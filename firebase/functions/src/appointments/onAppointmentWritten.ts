import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { affectsDebt } from "../utils/debt_calculation";
import { syncPatientDebt } from "../utils/recalculate_patient_debt";

const db = admin.firestore();

/**
 * Firestore Trigger: onAppointmentWritten
 *
 * Single owner of `patient.totalDebt`. Fires on every create / update / delete of
 * an appointment (client edits, FIFO distribution, LIFO reversal, interest cron,
 * recurring generation, occurrence cancellation) and recomputes the debt from
 * the unpaid appointments.
 *
 * Other triggers must NOT write `totalDebt` anymore; they only move money
 * (amountPaid / balance) and let this trigger converge the aggregate.
 */
export const onAppointmentWritten = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/appointments/{appointmentId}"
  )
  .onWrite(async (change, context) => {
    const { providerId, patientId, appointmentId } = context.params;

    if (!affectsDebt(change.before.data(), change.after.data())) return;

    try {
      const result = await syncPatientDebt(db, providerId, patientId);
      if (result && result.delta !== 0) {
        console.log(
          `[onAppointmentWritten] ${appointmentId} → patient ${patientId} debt resynced.`
        );
      }
    } catch (error) {
      console.error(`[onAppointmentWritten] Failed for ${appointmentId}:`, error);
      throw error;
    }
  });
