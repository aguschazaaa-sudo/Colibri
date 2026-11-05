import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { enqueueMessage } from "../utils/messaging_utils";

const db = admin.firestore();

/**
 * Callable Cloud Function: triggerManualReminders
 *
 * Allows a provider to maually trigger WhatsApp reminders for all
 * their patients that currently have outstanding debt (totalDebt > 0).
 * Each reminder is enqueued in the `message_queue` collection, which the
 * orchestrator later promotes to `communications` for actual delivery.
 */
export const triggerManualReminders = functions
  .runWith({ maxInstances: 5 })
  .https.onCall(async (_data: unknown, context: functions.https.CallableContext) => {
    // 1. Auth check (multi-tenant security)
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "El usuario no está autenticado."
      );
    }
    const providerId = context.auth.uid;

    try {
      const providerSnap = await db.collection("providers").doc(providerId).get();
      const providerData = providerSnap.data();
      if (!providerData || providerData.subscriptionStatus !== "active") {
        return {
          queued: 0,
          message: "La suscripcion no esta activa. No se enviaron recordatorios.",
        };
      }

      // 2. Fetch all patients of this provider with outstanding debt
      const patientsSnapshot = await db
        .collection("providers")
        .doc(providerId)
        .collection("patients")
        .where("totalDebt", ">", 0)
        .get();

      if (patientsSnapshot.empty) {
        return { queued: 0, message: "No hay pacientes con deuda pendiente." };
      }

      // 3. Queue a WhatsApp reminder for each patient via message_queue
      let queued = 0;
      let skipped = 0;

      // Derive day key in Buenos Aires timezone for idempotency
      const now = new Date();
      const baDate = new Date(now.toLocaleString("en-US", { timeZone: "America/Argentina/Buenos_Aires" }));
      const dayKey = `${baDate.getFullYear()}-${String(baDate.getMonth() + 1).padStart(2, "0")}-${String(baDate.getDate()).padStart(2, "0")}`;

      for (const patientDoc of patientsSnapshot.docs) {
        const patientData = patientDoc.data();
        const thirtyDaysFromNow = new Date(now);
        thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

        const result = await enqueueMessage({
          providerId,
          patientId: patientDoc.id,
          patientName: patientData.name ?? "",
          messageType: "payment_reminder",
          variables: {
            nombre_paciente: patientData.name ?? "",
            monto_total: patientData.totalDebt,
          },
          priority: 25,
          isUrgent: false,
          scheduledFor: now,
          expiresAt: thirtyDaysFromNow,
          idempotencyKey: `manual_${providerId}_${patientDoc.id}_${dayKey}`,
        });

        if (result.wasSkipped) {
          skipped++;
        } else {
          queued++;
        }
      }

      functions.logger.info(
        "[triggerManualReminders] Completed",
        { providerId, queued, skipped }
      );

      return {
        queued,
        skipped,
        message: `Se encolaron ${queued} recordatorio(s) para envío.${skipped > 0 ? ` ${skipped} ya estaban en cola.` : ""}`,
      };
    } catch (error: any) {
      if (error instanceof functions.https.HttpsError) throw error;
      console.error("[triggerManualReminders] Error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Error al encolar los recordatorios."
      );
    }
  });
