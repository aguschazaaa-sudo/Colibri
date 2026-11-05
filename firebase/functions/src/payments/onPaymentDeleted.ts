import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { applyDashboardDeltaInTx } from "../utils/metrics_utils";
import { revertPaymentLIFO } from "../utils/payment_distribution";

const db = admin.firestore();

/**
 * Firestore Trigger: onPaymentDeleted
 *
 * Fires when a payment document is hard deleted:
 *   providers/{providerId}/patients/{patientId}/payments/{paymentId}
 *
 * Responsibilities:
 *   1. Deducts the payment amount from the patient's `balance`.
 *   2. If the balance is insufficient to cover the reversal, the remainder becomes missing money that we must recover from appointments.
 *   3. It queries all appointments with `amountPaid > 0` ordered by date DESCENDING (LIFO).
 *   4. Substracts the missing money from these appointments, returning them to "unpaid", increasing `totalDebt`.
 *   5. Updates the dashboard inside the same transaction (atomic, retry-safe):
 *      `totalToCollect += newTotalDebt - currentTotalDebt` and
 *      `monthlyRevenue -= amount`.
 */
export const onPaymentDeleted = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/payments/{paymentId}"
  )
  .onDelete(async (snapshot, context) => {
    const { providerId, patientId, paymentId } = context.params;
    const paymentData = snapshot.data();

    if (!paymentData) return;

    const paymentAmount: number = paymentData.amount || 0;
    if (paymentAmount <= 0) return;

    const patientRef = db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId);

    try {
      await db.runTransaction(async (transaction) => {
        // NOTE: no state may leak out of this closure — Firestore re-runs it
        // on contention, so every value is recomputed per attempt.
        const patientDoc = await transaction.get(patientRef);

        if (!patientDoc.exists) {
          console.error(`[onPaymentDeleted] Patient ${patientId} not found.`);
          // No ledger to revert, but the revenue is still gone (same behavior
          // as before: revenue was decremented regardless of the patient doc).
          applyDashboardDeltaInTx(transaction, providerId, {
            monthlyRevenue: -paymentAmount,
          });
          return;
        }

        const patientData = patientDoc.data()!;
        const currentBalance: number = patientData.balance || 0;
        const currentTotalDebt: number = patientData.totalDebt || 0;

        let newBalance = currentBalance;
        let newTotalDebt = currentTotalDebt;

        // Try to deduct from balance first
        if (newBalance >= paymentAmount) {
          newBalance -= paymentAmount;
        } else {
          // Balance was not enough, we need to extract from appointments
          const missingMoney = paymentAmount - newBalance;
          newBalance = 0; // Balance is exhausted

          const paidAppointmentsQuery = patientRef
            .collection("appointments")
            .where("providerId", "==", providerId)
            // Querying for status IN ['liquidated', 'unpaid'] ensures we catch all that might have amountPaid > 0
            // but the cleanest way is `status != "unpaid"` (only works if no other statuses exist)
            // Or just fetch all and filter in memory, but let's query the ones that are likely paid.
            // Since we ordered the reverse index by status DESCENDING and date DESCENDING,
            // we can just fetch all and let the loop naturally skip amountPaid == 0.
            .orderBy("status", "desc")
            .orderBy("date", "desc");

          const paidSnapshot = await transaction.get(paidAppointmentsQuery);

          const { totalDebtIncrease } = revertPaymentLIFO(
            transaction,
            missingMoney,
            paidSnapshot.docs
          );

          newTotalDebt += totalDebtIncrease;
        }

        transaction.update(patientRef, {
          totalDebt: newTotalDebt,
          balance: newBalance,
        });

        // Dashboard: exact totalDebt change (debt to collect goes back up) and
        // lost revenue, committed atomically with the patient write.
        applyDashboardDeltaInTx(transaction, providerId, {
          totalToCollect: newTotalDebt - currentTotalDebt,
          monthlyRevenue: -paymentAmount,
        });

        functions.logger.info("[onPaymentDeleted] ledger reverted", { paymentId });
      });
    } catch (error) {
      console.error(`[onPaymentDeleted] Transaction failed for ${paymentId}:`, error);
      throw error;
    }
  });
