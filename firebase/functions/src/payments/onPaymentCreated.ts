import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { applyDashboardDeltaInTx } from "../utils/metrics_utils";
import { distributePaymentFIFO } from "../utils/payment_distribution";

const db = admin.firestore();

/**
 * Firestore Trigger: onPaymentCreated
 *
 * Fires when a new payment document is created under:
 *   providers/{providerId}/patients/{patientId}/payments/{paymentId}
 *
 * Responsibilities:
 *   1. Distributes the payment amount across unpaid appointments (FIFO by date,
 *      or to a specific appointment if `appointmentId` is set).
 *   2. Decreases the patient's totalDebt by the amount applied to appointments.
 *   3. Increases the patient's balance if there's leftover money after all debts.
 *   4. Updates the dashboard inside the same transaction (atomic, retry-safe):
 *      `totalToCollect += newTotalDebt - currentTotalDebt` (post-clamp) and
 *      `monthlyRevenue += amount`.
 */
export const onPaymentCreated = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/payments/{paymentId}"
  )
  .onCreate(async (snapshot, context) => {
    const { providerId, patientId, paymentId } = context.params;
    const paymentData = snapshot.data();

    if (!paymentData) {
      console.error(`[onPaymentCreated] No data for payment ${paymentId}`);
      return;
    }

    const paymentAmount: number = paymentData.amount || 0;
    if (paymentAmount <= 0) {
      console.log(`[onPaymentCreated] Payment ${paymentId} has no amount. Skipping.`);
      return;
    }

    const specificAppointmentId: string | null = paymentData.appointmentId || null;

    const patientRef = db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId);

    try {
      await db.runTransaction(async (transaction) => {
        // NOTE: no state may leak out of this closure — Firestore re-runs it
        // on contention, so every value is recomputed per attempt.
        // 1. Read patient + unpaid appointments (all reads before writes)
        const appointmentsQuery = patientRef
          .collection("appointments")
          .where("providerId", "==", providerId)
          .where("status", "==", "unpaid")
          .orderBy("date", "asc");

        const [patientDoc, unpaidSnapshot] = await Promise.all([
          transaction.get(patientRef),
          transaction.get(appointmentsQuery),
        ]);

        if (!patientDoc.exists) {
          console.error(`[onPaymentCreated] Patient ${patientId} not found.`);
          return;
        }

        const patientData = patientDoc.data()!;
        const currentTotalDebt: number = patientData.totalDebt || 0;
        const currentBalance: number = patientData.balance || 0;

        // 2. FIFO Payment Distribution
        const { totalDebtDecrease, leftoverBalance: moneyLeftForBalance } = distributePaymentFIFO(
          transaction,
          paymentAmount,
          unpaidSnapshot.docs,
          specificAppointmentId
        );

        // 3. Update patient's totalDebt and balance
        const newTotalDebt = Math.max(0, currentTotalDebt - totalDebtDecrease);
        const newBalance = currentBalance + moneyLeftForBalance;

        transaction.update(patientRef, {
          totalDebt: newTotalDebt,
          balance: newBalance,
        });

        // 4. Dashboard: exact (post-clamp) totalDebt change + revenue,
        //    committed atomically with the patient write.
        applyDashboardDeltaInTx(transaction, providerId, {
          totalToCollect: newTotalDebt - currentTotalDebt,
          monthlyRevenue: paymentAmount,
        });

        functions.logger.info("[onPaymentCreated] ledger updated", { paymentId });
      });
    } catch (error) {
      console.error(`[onPaymentCreated] Transaction failed for payment ${paymentId}:`, error);
      throw error; // Re-throw to trigger retry
    }
  });
