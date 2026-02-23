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

export const registerPayment = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
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

  try {
    // 3. Executing Firestore Transaction
    return await db.runTransaction(async (transaction: admin.firestore.Transaction) => {
      // References
      const patientRef = db.collection("patients").doc(payload.patientId);
      
      // We must explicitly query unpaid appointments for FIFO distribution
      // Note: In transactions, queries cannot follow writes, so we must read EVERYTHING first.
      const appointmentsQuery = db.collection("appointments")
        .where("providerId", "==", providerId)
        .where("patientId", "==", payload.patientId)
        .where("status", "==", "unpaid")
        .orderBy("date", "asc");
      
      const [patientDoc, unpaidAppointmentsSnapshot] = await Promise.all([
        transaction.get(patientRef),
        transaction.get(appointmentsQuery),
      ]);

      if (!patientDoc.exists) {
         throw new functions.https.HttpsError("not-found", "Paciente no encontrado.");
      }

      const patientData = patientDoc.data()!;
      if (patientData.providerId !== providerId) {
         throw new functions.https.HttpsError("permission-denied", "No tienes acceso a este paciente.");
      }

      // 4. Ledger Math Logic (FIFO Payment Distribution)
      let moneyLeftToDistribute = payload.amount;
      let totalDebtDecrease = 0;

      // Handle specific appointment or FIFO
      const targetDocs = payload.appointmentId 
         ? unpaidAppointmentsSnapshot.docs.filter(doc => doc.id === payload.appointmentId)
         : unpaidAppointmentsSnapshot.docs;

      for (const doc of targetDocs as admin.firestore.QueryDocumentSnapshot[]) {
        if (moneyLeftToDistribute <= 0) break;

        const appData = doc.data();
        const pendingAmount = appData.totalAmount - appData.amountPaid;
        
        if (pendingAmount > 0) {
           const amountToApplyToThisAppointment = Math.min(moneyLeftToDistribute, pendingAmount);
           
           const newAmountPaid = appData.amountPaid + amountToApplyToThisAppointment;
           const newStatus = newAmountPaid >= appData.totalAmount ? 'liquidated' : 'unpaid';
           
           transaction.update(doc.ref, {
             amountPaid: newAmountPaid,
             status: newStatus,
           });

           moneyLeftToDistribute -= amountToApplyToThisAppointment;
           totalDebtDecrease += amountToApplyToThisAppointment;
        }
      }

      // Calculate final patient balance updates
      const currentPatientDebt = patientData.totalDebt || 0;
      const currentPatientBalance = patientData.balance || 0;

      // If moneyLeft > 0, the rest goes to patient's balance in favor
      const newTotalDebt = Math.max(0, currentPatientDebt - totalDebtDecrease);
      const newBalance = currentPatientBalance + moneyLeftToDistribute;

      transaction.update(patientRef, {
        totalDebt: newTotalDebt,
        balance: newBalance,
      });

      // 5. Create Payment Record (The ledger entry)
      const newPaymentRef = db.collection("payments").doc();
      transaction.set(newPaymentRef, {
        patientId: payload.patientId,
        providerId: providerId,
        appointmentId: payload.appointmentId || null,
        amount: payload.amount,
        date: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { 
        success: true, 
        paymentId: newPaymentRef.id, 
        moneyToBalance: moneyLeftToDistribute 
      };
    });
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    console.error("Payment Transaction failed:", error);
    throw new functions.https.HttpsError("internal", "Error procesando el pago en el servidor.");
  }
});
