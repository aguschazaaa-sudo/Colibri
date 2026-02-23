"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendWhatsAppReminder = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();
/**
 * Worker that triggers when a communication is queued.
 * It uses the 'check-before-write' principle to avoid duplicates.
 */
exports.sendWhatsAppReminder = functions.firestore
    .document("communications/{commId}")
    .onCreate(async (snap, context) => {
    const commId = context.params.commId;
    const data = snap.data();
    if (data.status !== "pending") {
        console.log(`Communication ${commId} is not pending. Status: ${data.status}`);
        return null;
    }
    const { providerId, patientId, type, totalDebtAtThatTime } = data;
    if (type !== "whatsapp_reminder") {
        return null; // Only process whatsapp reminders for now
    }
    try {
        // 1. Idempotency Check (Check-before-write)
        // E.g., make sure we haven't sent a reminder to this patient in the last 24h
        const oneDayAgo = new Date();
        oneDayAgo.setDate(oneDayAgo.getDate() - 1);
        const recentMessages = await db.collection("communications")
            .where("providerId", "==", providerId)
            .where("patientId", "==", patientId)
            .where("type", "==", "whatsapp_reminder")
            .where("status", "==", "sent")
            .where("sentAt", ">", admin.firestore.Timestamp.fromDate(oneDayAgo))
            .limit(1)
            .get();
        if (!recentMessages.empty) {
            console.log(`[Idempotency] A reminder was already sent to patient ${patientId} in the last 24h. Aborting.`);
            await snap.ref.update({
                status: "aborted",
                reason: "duplicate_in_24h",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return null;
        }
        // 2. Format Message
        // TODO: Fetch Provider's custom template. For now, we use a default.
        const messageBody = `Hola! Te recordamos que tienes un saldo pendiente de $${totalDebtAtThatTime}. Por favor comunicate con la administración para regularizarlo.`;
        console.log(`[WhatsApp API Mock] Sending to patient ${patientId}: ${messageBody}`);
        // 3. Call WhatsApp API
        // TODO: Implement axios/fetch to Meta Graph API
        // const response = await axios.post("https://graph.facebook.com/vXX.X/...", payload, headers);
        // Simulating network delay
        await new Promise(resolve => setTimeout(resolve, 1000));
        // 4. Mark as Sent
        await snap.ref.update({
            status: "sent",
            messageId: `mock-msg-id-${Date.now()}`,
            deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Successfully processed reminder ${commId}`);
        return null;
    }
    catch (error) {
        console.error(`Failed to send WhatsApp reminder ${commId}`, error);
        await snap.ref.update({
            status: "failed",
            error: String(error),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
    }
});
//# sourceMappingURL=sendWhatsAppReminder.js.map