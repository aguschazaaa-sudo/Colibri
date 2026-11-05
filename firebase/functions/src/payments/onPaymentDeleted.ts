import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { incrementDashboardMetrics } from "../utils/metrics_utils";
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
 *   4. Substracts the missing money from these appointments, returning them to "unpaid".
 *      `onAppointmentWritten` then recomputes `totalDebt`.
 *   5. Updates the dashboard's `monthlyRevenue` metric.
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
        const patientDoc = await transaction.get(patientRef);

        if (!patientDoc.exists) {
          console.error(`[onPaymentDeleted] Patient ${patientId} not found.`);
          return;
        }

        const patientData = patientDoc.data()!;
        const currentBalance: number = patientData.balance || 0;

        let newBalance = currentBalance;

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

          // Un-pays appointments (LIFO); onAppointmentWritten recomputes totalDebt.
          revertPaymentLIFO(transaction, missingMoney, paidSnapshot.docs);
        }

        transaction.update(patientRef, { balance: newBalance });

        console.log(`[onPaymentDeleted] Reverted payment ${paymentId}.`);
      });

      // Revenue metric only; totalToCollect is owned by onAppointmentWritten.
      await incrementDashboardMetrics(providerId, {
        monthlyRevenue: -paymentAmount,
      });
    } catch (error) {
      console.error(`[onPaymentDeleted] Transaction failed for ${paymentId}:`, error);
      throw error;
    }
  });
