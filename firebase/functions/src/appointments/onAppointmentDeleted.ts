import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { distributePaymentFIFO } from "../utils/payment_distribution";

const db = admin.firestore();

/**
 * Firestore Trigger: onAppointmentDeleted
 *
 * Fires when an appointment document is hard deleted:
 *   providers/{providerId}/patients/{patientId}/appointments/{appointmentId}
 *
 * Responsibility: money already paid to this appointment (`amountPaid > 0`) is
 * "freed" and redistributed via FIFO to other unpaid appointments; any leftover
 * goes to the patient's `balance`.
 *
 * The pending debt of the deleted appointment disappears automatically:
 * `onAppointmentWritten` recomputes `totalDebt` from the remaining appointments.
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

    const amountPaid: number = appData.amountPaid || 0;
    if (amountPaid <= 0) return;

    const patientRef = db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId);

    try {
      await db.runTransaction(async (transaction) => {
        const unpaidQuery = patientRef
          .collection("appointments")
          .where("providerId", "==", providerId)
          .where("status", "==", "unpaid")
          .orderBy("date", "asc");

        const [patientDoc, unpaidSnapshot] = await Promise.all([
          transaction.get(patientRef),
          transaction.get(unpaidQuery),
        ]);

        if (!patientDoc.exists) {
          console.error(`[onAppointmentDeleted] Patient ${patientId} not found.`);
          return;
        }

        const { leftoverBalance } = distributePaymentFIFO(
          transaction,
          amountPaid,
          unpaidSnapshot.docs
        );

        if (leftoverBalance > 0) {
          const currentBalance: number = patientDoc.data()!.balance || 0;
          transaction.update(patientRef, {
            balance: currentBalance + leftoverBalance,
          });
        }

        console.log(
          `[onAppointmentDeleted] Deleted ${appointmentId}. Freed money redistributed.`
        );
      });
    } catch (error) {
      console.error(`[onAppointmentDeleted] Transaction failed for ${appointmentId}:`, error);
      throw error;
    }
  });
