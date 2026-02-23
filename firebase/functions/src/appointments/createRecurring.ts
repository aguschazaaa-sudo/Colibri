import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { z } from "zod";
import { computeNextDate } from "../utils/dateAndInterest";

const db = admin.firestore();

const CreateRecurringRequestSchema = z.object({
  patientId: z.string().min(1),
  concept: z.string().min(1),
  amount: z.number().positive(),
  frequency: z.enum(["weekly", "biweekly", "monthly_pattern", "monthly_28days"]),
  baseDate: z.string(), // ISO string from frontend
  occurrences: z.number().min(1).max(52).default(12), // How many to generate ahead
});

export const createRecurring = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "El usuario no está autenticado.");
  }
  const providerId = context.auth.uid;

  const validationResult = CreateRecurringRequestSchema.safeParse(data);
  if (!validationResult.success) {
    throw new functions.https.HttpsError("invalid-argument", "Los datos enviados son inválidos.", validationResult.error.issues);
  }

  const payload = validationResult.data;
  const baseDateObj = new Date(payload.baseDate);

  try {
    return await db.runTransaction(async (transaction) => {
      // 1. Validate Patient
      const patientRef = db.collection("patients").doc(payload.patientId);
      const patientDoc = await transaction.get(patientRef);

      if (!patientDoc.exists || patientDoc.data()?.providerId !== providerId) {
        throw new functions.https.HttpsError("permission-denied", "Paciente no encontrado o sin acceso.");
      }

      // 2. Create the recurring template
      const recurringRef = db.collection("recurring_appointments").doc();
      transaction.set(recurringRef, {
        patientId: payload.patientId,
        providerId: providerId,
        concept: payload.concept,
        defaultAmount: payload.amount,
        frequency: payload.frequency,
        baseDate: admin.firestore.Timestamp.fromDate(baseDateObj),
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 3. Generate future appointments
      const batchCreates: admin.firestore.DocumentReference[] = [];
      let currentDate = new Date(baseDateObj);

      for (let i = 0; i < payload.occurrences; i++) {
        const appointmentRef = db.collection("appointments").doc();
        batchCreates.push(appointmentRef);
        
        transaction.set(appointmentRef, {
            patientId: payload.patientId,
            providerId: providerId,
            recurringAppointmentId: recurringRef.id,
            concept: payload.concept,
            date: admin.firestore.Timestamp.fromDate(new Date(currentDate)),
            totalAmount: payload.amount,
            amountPaid: 0,
            status: "unpaid",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Compute next date
        currentDate = computeNextDate(currentDate, payload.frequency);
      }

      return {
        success: true,
        recurringAppointmentId: recurringRef.id,
        generatedCount: batchCreates.length,
      };
    });
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.error("Failed to create recurring appointments:", error);
    throw new functions.https.HttpsError("internal", "Error generando los turnos recurrentes.");
  }
});


