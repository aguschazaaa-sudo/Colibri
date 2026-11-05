import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { applyDashboardDeltaInTx } from "../utils/metrics_utils";
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
 *   3. Updates the dashboard's `totalToCollect` by exactly
 *      `newTotalDebt - currentTotalDebt` (post-clamp), inside the same
 *      transaction (atomic, retry-safe).
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
    const isScheduled = appData.status === "scheduled";
    const pendingDebt = isScheduled ? 0 : Math.max(0, totalAmount - amountPaid);

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
          console.error(`[onAppointmentDeleted] Patient ${patientId} not found.`);
          return;
        }

        const patientData = patientDoc.data()!;
        const currentTotalDebt: number = patientData.totalDebt || 0;
        const currentBalance: number = patientData.balance || 0;

        let newTotalDebt = Math.max(0, currentTotalDebt - pendingDebt);
        let newBalance = currentBalance;

        // If money was paid to this appointment, it becomes "freed" and acts like a new payment
        if (!isScheduled && amountPaid > 0) {
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
        }

        transaction.update(patientRef, {
          totalDebt: newTotalDebt,
          balance: newBalance,
        });

        // Dashboard delta = exact (post-clamp) change written to
        // patient.totalDebt, committed atomically with the patient write.
        applyDashboardDeltaInTx(transaction, providerId, {
          totalToCollect: newTotalDebt - currentTotalDebt,
        });

        functions.logger.info("[onAppointmentDeleted] ledger updated", { appointmentId });
      });

      // Cancel any queued reminders for this appointment
      try {
        const queueSnap = await db
          .collection("message_queue")
          .where("providerId", "==", providerId)
          .where("sourceAppointmentId", "==", appointmentId)
          .where("status", "==", "queued")
          .get();

        if (!queueSnap.empty) {
          const cancelBatch = db.batch();
          for (const doc of queueSnap.docs) {
            cancelBatch.update(doc.ref, { status: "cancelled" });
          }
          await cancelBatch.commit();
          functions.logger.info(
            `[onAppointmentDeleted] Cancelled ${queueSnap.size} queued reminder(s)`,
            { appointmentId }
          );
        }
      } catch (cancelError) {
        functions.logger.warn(
          "[onAppointmentDeleted] Failed to cancel queued reminders",
          { appointmentId, error: String(cancelError) }
        );
      }
    } catch (error) {
      console.error(`[onAppointmentDeleted] Transaction failed for ${appointmentId}:`, error);
      throw error;
    }
  });
