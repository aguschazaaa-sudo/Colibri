import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Firestore Trigger: onAppointmentCreated
 *
 * Fires when a new appointment document is created under:
 *   providers/{providerId}/patients/{patientId}/appointments/{appointmentId}
 *
 * Responsibilities:
 *   1. Increases the patient's totalDebt by the appointment's totalAmount.
 *   2. If the patient has a positive balance (saldo a favor), auto-applies it
 *      to the new appointment (partial or full liquidation).
 */
export const onAppointmentCreated = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/appointments/{appointmentId}"
  )
  .onCreate(async (snapshot, context) => {
    const { providerId, patientId, appointmentId } = context.params;
    const appointmentData = snapshot.data();

    if (!appointmentData) {
      console.error(`[onAppointmentCreated] No data for appointment ${appointmentId}`);
      return;
    }

    const totalAmount: number = appointmentData.totalAmount || 0;
    if (totalAmount <= 0) {
      console.log(`[onAppointmentCreated] Appointment ${appointmentId} has no amount. Skipping.`);
      return;
    }

    const patientRef = db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId);

    const appointmentRef = patientRef
      .collection("appointments")
      .doc(appointmentId);

    try {
      await db.runTransaction(async (transaction) => {
        const patientDoc = await transaction.get(patientRef);

        if (!patientDoc.exists) {
          console.error(`[onAppointmentCreated] Patient ${patientId} not found.`);
          return;
        }

        const patientData = patientDoc.data()!;
        const currentBalance: number = patientData.balance || 0;
        const currentTotalDebt: number = patientData.totalDebt || 0;

        if (currentBalance >= totalAmount) {
          // Balance covers the entire appointment → auto-liquidate
          transaction.update(appointmentRef, {
            amountPaid: totalAmount,
            status: "liquidated",
          });

          transaction.update(patientRef, {
            balance: currentBalance - totalAmount,
            // totalDebt doesn't change: debt was created and instantly liquidated
          });

          console.log(
            `[onAppointmentCreated] Auto-liquidated appointment ${appointmentId}. ` +
            `Balance: ${currentBalance} → ${currentBalance - totalAmount}`
          );
        } else if (currentBalance > 0) {
          // Partial balance → apply what we have
          transaction.update(appointmentRef, {
            amountPaid: currentBalance,
            status: "unpaid",
          });

          const netDebtIncrease = totalAmount - currentBalance;
          transaction.update(patientRef, {
            balance: 0,
            totalDebt: currentTotalDebt + netDebtIncrease,
          });

          console.log(
            `[onAppointmentCreated] Partial balance applied to ${appointmentId}. ` +
            `Balance used: ${currentBalance}. Net debt increase: ${netDebtIncrease}`
          );
        } else {
          // No balance → full debt increase
          transaction.update(patientRef, {
            totalDebt: currentTotalDebt + totalAmount,
          });

          console.log(
            `[onAppointmentCreated] Debt increased for patient ${patientId}. ` +
            `totalDebt: ${currentTotalDebt} → ${currentTotalDebt + totalAmount}`
          );
        }
      });
    } catch (error) {
      console.error(`[onAppointmentCreated] Transaction failed for ${appointmentId}:`, error);
      throw error; // Re-throw to trigger retry
    }
  });
