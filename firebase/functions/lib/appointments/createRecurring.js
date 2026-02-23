"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createRecurring = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const zod_1 = require("zod");
const dateAndInterest_1 = require("../utils/dateAndInterest");
const db = admin.firestore();
const CreateRecurringRequestSchema = zod_1.z.object({
    patientId: zod_1.z.string().min(1),
    concept: zod_1.z.string().min(1),
    amount: zod_1.z.number().positive(),
    frequency: zod_1.z.enum(["weekly", "biweekly", "monthly_pattern", "monthly_28days"]),
    baseDate: zod_1.z.string(),
    occurrences: zod_1.z.number().min(1).max(52).default(12), // How many to generate ahead
});
exports.createRecurring = functions.https.onCall(async (data, context) => {
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
            var _a;
            // 1. Validate Patient
            const patientRef = db.collection("patients").doc(payload.patientId);
            const patientDoc = await transaction.get(patientRef);
            if (!patientDoc.exists || ((_a = patientDoc.data()) === null || _a === void 0 ? void 0 : _a.providerId) !== providerId) {
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
            const batchCreates = [];
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
                currentDate = (0, dateAndInterest_1.computeNextDate)(currentDate, payload.frequency);
            }
            return {
                success: true,
                recurringAppointmentId: recurringRef.id,
                generatedCount: batchCreates.length,
            };
        });
    }
    catch (error) {
        if (error instanceof functions.https.HttpsError)
            throw error;
        console.error("Failed to create recurring appointments:", error);
        throw new functions.https.HttpsError("internal", "Error generando los turnos recurrentes.");
    }
});
//# sourceMappingURL=createRecurring.js.map