import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { applyDashboardDeltaInTx } from "../utils/metrics_utils";
import { enqueueUrgentAppointmentReminder } from "../utils/messaging_utils";

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
 *   3. Increments the dashboard's `totalToCollect` by the exact change written
 *      to `patient.totalDebt`, inside the same transaction (atomic, retry-safe).
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

    const appointmentDate: admin.firestore.Timestamp = appointmentData.date;
    const now = new Date();
    if (appointmentDate?.toDate && appointmentDate.toDate() > now) {
      // Future appointment: do not generate debt yet.
      // If totalAmount === 0 (e.g. obra social / free visit) mark as liquidated
      // immediately; otherwise keep it scheduled.
      if (totalAmount <= 0) {
        console.log(
          `[onAppointmentCreated] Appointment ${appointmentId} is future with no amount. Marking liquidated.`
        );
        await snapshot.ref.update({
          status: "liquidated",
          amountPaid: 0,
          _functionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await snapshot.ref.update({
          status: "scheduled",
          amountPaid: 0,
          _functionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Fast-path: queue urgent appointment reminder for premium providers
      // when appointment is less than 48h away.
      // Applies to ALL future appointments regardless of amount (including free ones).
      const appointmentTime = appointmentDate.toDate().getTime();
      const hoursUntilAppointment = (appointmentTime - now.getTime()) / (1000 * 60 * 60);

      if (hoursUntilAppointment >= 2 && hoursUntilAppointment < 48) {
        try {
          const providerDoc = await db.collection("providers").doc(providerId).get();
          const provData = providerDoc.data();

          if (
            provData &&
            provData.subscriptionStatus === "active" &&
            provData.plan === "premium"
          ) {
            const patDoc = await db
              .collection("providers")
              .doc(providerId)
              .collection("patients")
              .doc(patientId)
              .get();
            const patientName = patDoc.data()?.name ?? "";

            await enqueueUrgentAppointmentReminder(
              appointmentId,
              { date: appointmentDate, concept: appointmentData.concept },
              { name: provData.name, profession: provData.profession },
              providerId,
              patientId,
              patientName
            );

            functions.logger.info(
              "[onAppointmentCreated] Urgent appointment reminder queued",
              { appointmentId, hoursUntil: Math.round(hoursUntilAppointment) }
            );
          }
        } catch (queueError) {
          functions.logger.warn(
            "[onAppointmentCreated] Failed to queue urgent reminder",
            { appointmentId, error: String(queueError) }
          );
        }
      }

      return;
    }

    // Past appointment with no amount: mark liquidated, nothing else to do.
    if (totalAmount <= 0) {
      console.log(
        `[onAppointmentCreated] Appointment ${appointmentId} is past with no amount. Marking liquidated.`
      );
      await snapshot.ref.update({
        status: "liquidated",
        amountPaid: 0,
        _functionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
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
        // NOTE: no state may leak out of this closure — Firestore re-runs it
        // on contention, so every value is recomputed per attempt.
        const patientDoc = await transaction.get(patientRef);

        if (!patientDoc.exists) {
          console.error(`[onAppointmentCreated] Patient ${patientId} not found.`);
          return;
        }

        const patientData = patientDoc.data()!;
        const currentBalance: number = patientData.balance || 0;
        const currentTotalDebt: number = patientData.totalDebt || 0;
        let newTotalDebt = currentTotalDebt;

        if (currentBalance >= totalAmount) {
          // Balance covers the entire appointment → auto-liquidate, debt unchanged
          transaction.update(appointmentRef, {
            amountPaid: totalAmount,
            status: "liquidated",
            _functionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          transaction.update(patientRef, {
            balance: currentBalance - totalAmount,
          });

          functions.logger.info(
            `[onAppointmentCreated] Auto-liquidated appointment ${appointmentId}.`
          );
        } else if (currentBalance > 0) {
          // Partial balance → apply what we have
          transaction.update(appointmentRef, {
            amountPaid: currentBalance,
            status: "unpaid",
            _functionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          newTotalDebt = currentTotalDebt + (totalAmount - currentBalance);
          transaction.update(patientRef, {
            balance: 0,
            totalDebt: newTotalDebt,
          });

          functions.logger.info(
            `[onAppointmentCreated] Partial balance applied to ${appointmentId}.`
          );
        } else {
          // No balance → full debt increase
          newTotalDebt = currentTotalDebt + totalAmount;
          transaction.update(patientRef, {
            totalDebt: newTotalDebt,
          });

          functions.logger.info(
            `[onAppointmentCreated] Debt increased for patient ${patientId}.`
          );
        }

        // Dashboard delta = exact change written to patient.totalDebt,
        // committed atomically with the patient write.
        applyDashboardDeltaInTx(transaction, providerId, {
          totalToCollect: newTotalDebt - currentTotalDebt,
        });
      });
    } catch (error) {
      console.error(`[onAppointmentCreated] Transaction failed for ${appointmentId}:`, error);
      throw error; // Re-throw to trigger retry
    }
  });
