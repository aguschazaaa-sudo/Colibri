import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { z } from "zod";

const db = admin.firestore();

// Input Validation Schema using Zod
const RegisterPaymentRequestSchema = z.object({
  patientId: z.string().min(1),
  amount: z.number().positive(),
  appointmentId: z.string().optional(),
});

/**
 * Callable Cloud Function: registerPayment
 *
 * Validates the request and creates a payment document.
 * The actual FIFO distribution and totalDebt/balance updates are handled
 * by the `onPaymentCreated` Firestore trigger.
 */
export const registerPayment = functions
  .runWith({ maxInstances: 10 })
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // 1. Validate Authentication (Multi-tenant security)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "El usuario no está autenticado."
    );
  }
  const providerId = context.auth.uid;

  // 2. Validate Input Payload
  const validationResult = RegisterPaymentRequestSchema.safeParse(data);
  if (!validationResult.success) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Los datos enviados son inválidos.",
      validationResult.error.issues
    );
  }
  
  const payload = validationResult.data;

  // Helper: base path for the patient document
  const patientRef = db
    .collection("providers")
    .doc(providerId)
    .collection("patients")
    .doc(payload.patientId);

  try {
    // 3. Verify patient exists and belongs to this provider
    const patientDoc = await patientRef.get();

    if (!patientDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Paciente no encontrado.");
    }

    const patientData = patientDoc.data()!;
    if (patientData.providerId !== providerId) {
      throw new functions.https.HttpsError("permission-denied", "No tienes acceso a este paciente.");
    }

    // 4. Create Payment Record (the onPaymentCreated trigger handles the rest)
    const newPaymentRef = patientRef.collection("payments").doc();
    await newPaymentRef.set({
      patientId: payload.patientId,
      providerId: providerId,
      appointmentId: payload.appointmentId || null,
      amount: payload.amount,
      date: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { 
      success: true, 
      paymentId: newPaymentRef.id,
    };
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error("Payment creation failed:", error);
    throw new functions.https.HttpsError("internal", "Error procesando el pago en el servidor.");
  }
});
