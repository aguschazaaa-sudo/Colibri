import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Callable Cloud Function: triggerManualReminders
 *
 * Allows a provider to maually trigger WhatsApp reminders for all
 * their patients that currently have outstanding debt (totalDebt > 0).
 * Each reminder is queued as a `communications` document, which is then
 * picked up by the `sendWhatsAppReminder` Firestore trigger.
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

      // 3. Queue a WhatsApp reminder for each patient
      const batch = db.batch();
      let queued = 0;

      for (const patientDoc of patientsSnapshot.docs) {
        const patientData = patientDoc.data();
        const commRef = db.collection("communications").doc();

        batch.set(commRef, {
          providerId: providerId,
          patientId: patientDoc.id,
          type: "whatsapp_reminder",
          status: "pending",
          totalDebtAtThatTime: patientData.totalDebt,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        queued++;
      }

      await batch.commit();

      console.log(
        `[triggerManualReminders] Provider ${providerId} queued ${queued} reminders.`
      );

      return {
        queued,
        message: `Se encolaron ${queued} recordatorio(s) para envío.`,
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
