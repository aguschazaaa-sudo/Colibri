import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { incrementDashboardMetrics } from "../utils/metrics_utils";
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
 *   2. Increases the patient's balance if there's leftover money after all debts.
 *   3. Marks the payment with `appliedAt` (idempotency guard for retries).
 *
 * `totalDebt` is NOT written here: `onAppointmentWritten` recomputes it from
 * the appointments this trigger updates.
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

    const paymentRef = snapshot.ref;

    try {
      const txResult = await db.runTransaction(async (transaction) => {
        // 1. Read payment + patient + unpaid appointments (all reads before writes)
        const appointmentsQuery = patientRef
          .collection("appointments")
          .where("providerId", "==", providerId)
          .where("status", "==", "unpaid")
          .orderBy("date", "asc");

        const [paymentDoc, patientDoc, unpaidSnapshot] = await Promise.all([
          transaction.get(paymentRef),
          transaction.get(patientRef),
          transaction.get(appointmentsQuery),
        ]);

        // Idempotency guard: triggers are delivered at-least-once. Without this
        // a retried event would distribute the same payment twice.
        if (!paymentDoc.exists || paymentDoc.data()?.appliedAt) {
          console.log(`[onPaymentCreated] Payment ${paymentId} already applied. Skipping.`);
          return;
        }

        if (!patientDoc.exists) {
          console.error(`[onPaymentCreated] Patient ${patientId} not found.`);
          return;
        }

        const currentBalance: number = patientDoc.data()!.balance || 0;

        // 2. FIFO Payment Distribution (updates appointments' amountPaid/status;
        //    `onAppointmentWritten` recomputes totalDebt from them).
        const { leftoverBalance } = distributePaymentFIFO(
          transaction,
          paymentAmount,
          unpaidSnapshot.docs,
          specificAppointmentId
        );

        // 3. Leftover money → saldo a favor
        if (leftoverBalance > 0) {
          transaction.update(patientRef, {
            balance: currentBalance + leftoverBalance,
          });
        }

        transaction.update(paymentRef, {
          appliedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`[onPaymentCreated] Payment ${paymentId} processed.`);

        return { totalPaymentAmount: paymentAmount };
      });

      // Revenue metric only; totalToCollect is owned by onAppointmentWritten.
      if (txResult) {
        await incrementDashboardMetrics(providerId, {
          monthlyRevenue: txResult.totalPaymentAmount,
        });
      }
    } catch (error) {
      console.error(`[onPaymentCreated] Transaction failed for payment ${paymentId}:`, error);
      throw error; // Re-throw to trigger retry
    }
  });
