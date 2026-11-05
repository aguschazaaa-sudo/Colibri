import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Firestore Trigger: onAppointmentCreated
 *
 * Fires when a new appointment document is created under:
 *   providers/{providerId}/patients/{patientId}/appointments/{appointmentId}
 *
 * Responsibility: if the patient has a positive balance (saldo a favor),
 * auto-apply it to the new appointment (partial or full liquidation).
 *
 * `totalDebt` and dashboard `totalToCollect` are owned by `onAppointmentWritten`,
 * which recomputes them from the unpaid appointments after this runs.
 */
export const onAppointmentCreated = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/appointments/{appointmentId}"
  )
  .onCreate(async (snapshot, context) => {
    const { providerId, patientId, appointmentId } = context.params;

    const patientRef = db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId);

    const appointmentRef = snapshot.ref;

    try {
      await db.runTransaction(async (transaction) => {
        // Re-read inside the transaction: on a retried delivery the balance may
        // already have been applied, so we work from the current state.
        const [patientDoc, appointmentDoc] = await Promise.all([
          transaction.get(patientRef),
          transaction.get(appointmentRef),
        ]);

        if (!patientDoc.exists || !appointmentDoc.exists) return;

        const appData = appointmentDoc.data()!;
        if (appData.status !== "unpaid") return;

        const totalAmount: number = appData.totalAmount || 0;
        const amountPaid: number = appData.amountPaid || 0;
        const pending = totalAmount - amountPaid;
        const currentBalance: number = patientDoc.data()!.balance || 0;

        if (pending <= 0 || currentBalance <= 0) return;

        const applied = Math.min(currentBalance, pending);
        const newAmountPaid = amountPaid + applied;

        transaction.update(appointmentRef, {
          amountPaid: newAmountPaid,
          status: newAmountPaid >= totalAmount ? "liquidated" : "unpaid",
        });
        transaction.update(patientRef, {
          balance: currentBalance - applied,
        });

        console.log(
          `[onAppointmentCreated] Balance applied to appointment ${appointmentId}.`
        );
      });
    } catch (error) {
      console.error(`[onAppointmentCreated] Transaction failed for ${appointmentId}:`, error);
      throw error; // Re-throw to trigger retry
    }
  });
