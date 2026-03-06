import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { incrementDashboardMetrics } from "../utils/metrics_utils";
import { distributePaymentFIFO } from "../utils/payment_distribution";

const db = admin.firestore();

/**
 * Firestore Trigger: onAppointmentDeleted
 *
 * Fires when an appointment document is hard deleted:
 *   providers/{providerId}/patients/{patientId}/appointments/{appointmentId}
 *
 * Responsibilities:
 *   1. Decreases the patient's `totalDebt` by the pending debt (totalAmount - amountPaid).
 *   2. If the appointment had partial or full payments (`amountPaid > 0`), that money is "freed".
 *      It gets redistributed via FIFO to other unpaid appointments using `distributePaymentFIFO`.
 *      Any leftover money increases the patient's `balance`.
 *   3. Updates the dashboard's `totalToCollect` metrics.
 */
export const onAppointmentDeleted = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/appointments/{appointmentId}"
  )
  .onDelete(async (snapshot, context) => {
    const { providerId, patientId, appointmentId } = context.params;
    const appData = snapshot.data();

    if (!appData) return;

    const totalAmount: number = appData.totalAmount || 0;
    const amountPaid: number = appData.amountPaid || 0;
    const pendingDebt = Math.max(0, totalAmount - amountPaid);

    const patientRef = db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId);

    let netDebtDecrease = 0;

    try {
      await db.runTransaction(async (transaction) => {
        const patientDoc = await transaction.get(patientRef);

        if (!patientDoc.exists) {
          console.error(`[onAppointmentDeleted] Patient ${patientId} not found.`);
          return;
        }

        const patientData = patientDoc.data()!;
        const currentTotalDebt: number = patientData.totalDebt || 0;
        const currentBalance: number = patientData.balance || 0;

        let newTotalDebt = Math.max(0, currentTotalDebt - pendingDebt);
        let newBalance = currentBalance;
        netDebtDecrease += pendingDebt;

        // If money was paid to this appointment, it becomes "freed" and acts like a new payment
        if (amountPaid > 0) {
          const appointmentsQuery = patientRef
            .collection("appointments")
            .where("providerId", "==", providerId)
            .where("status", "==", "unpaid")
            .orderBy("date", "asc");

          const unpaidSnapshot = await transaction.get(appointmentsQuery);

          const { totalDebtDecrease: redistributedDebtDecrease, leftoverBalance } = distributePaymentFIFO(
            transaction,
            amountPaid,
            unpaidSnapshot.docs
          );

          newTotalDebt = Math.max(0, newTotalDebt - redistributedDebtDecrease);
          newBalance += leftoverBalance;
          netDebtDecrease += redistributedDebtDecrease;
        }

        transaction.update(patientRef, {
          totalDebt: newTotalDebt,
          balance: newBalance,
        });

        console.log(
          `[onAppointmentDeleted] Deleted ${appointmentId}. ` +
          `Debt removed: ${pendingDebt}. Freed money: ${amountPaid}. ` +
          `totalDebt: ${currentTotalDebt} → ${newTotalDebt}. ` +
          `balance: ${currentBalance} → ${newBalance}`
        );
      });

      // Update the provider's pre-calculated dashboard metrics outside the transaction.
      if (netDebtDecrease > 0) {
        await incrementDashboardMetrics(providerId, { totalToCollect: -netDebtDecrease });
      }
    } catch (error) {
      console.error(`[onAppointmentDeleted] Transaction failed for ${appointmentId}:`, error);
      throw error;
    }
  });
