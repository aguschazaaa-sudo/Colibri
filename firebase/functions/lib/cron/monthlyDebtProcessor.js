"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.monthlyDebtProcessor = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const dateAndInterest_1 = require("../utils/dateAndInterest");
const db = admin.firestore();
/**
 * Cron Job that runs on the 28th of every month at 15:00.
 * 1. Finds unpaid appointments older than 1 month.
 * 2. Applies monthly interest to the remaining amount.
 * 3. Updates Patient's totalDebt.
 * 4. Triggers WhatsApp reminder logic.
 */
exports.monthlyDebtProcessor = functions.pubsub.schedule("0 15 28 * *")
    .timeZone("America/Argentina/Buenos_Aires") // Configurable, assuming local time
    .onRun(async (context) => {
    console.log("Started monthlyDebtProcessor");
    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
    // Ensure we handle changes in batches and use transactions/batches where appropriate.
    // However, since we process patients, we can process patient by patient.
    // Get all patients that have debt
    const patientsWithDebtSnapshot = await db.collection("patients")
        .where("totalDebt", ">", 0)
        .get();
    if (patientsWithDebtSnapshot.empty) {
        console.log("No patients with debt found.");
        return null;
    }
    console.log(`Processing debt for ${patientsWithDebtSnapshot.size} patients`);
    const batch = db.batch();
    let updatesCount = 0;
    for (const patientDoc of patientsWithDebtSnapshot.docs) {
        const patientId = patientDoc.id;
        const patientData = patientDoc.data();
        const providerId = patientData.providerId;
        // Find unpaid appointments for this patient
        const unpaidAppointmentsSnapshot = await db.collection("appointments")
            .where("patientId", "==", patientId)
            .where("status", "==", "unpaid")
            .get();
        let totalInterestAddedToPatient = 0;
        for (const appDoc of unpaidAppointmentsSnapshot.docs) {
            const appData = appDoc.data();
            const appDate = appData.date;
            // Check if appointment is older than 1 month
            if (appDate.toDate() < oneMonthAgo) {
                const pendingAmount = appData.totalAmount - (appData.amountPaid || 0);
                if (pendingAmount > 0) {
                    // Apply compound interest
                    const interestAmount = (0, dateAndInterest_1.calculateInterest)(pendingAmount, dateAndInterest_1.MONTHLY_INTEREST_RATE);
                    const newTotalAmount = appData.totalAmount + interestAmount;
                    batch.update(appDoc.ref, {
                        totalAmount: newTotalAmount,
                    });
                    totalInterestAddedToPatient += interestAmount;
                    updatesCount++;
                }
            }
        }
        // Update patient's total debt if interest was added
        if (totalInterestAddedToPatient > 0) {
            const newTotalDebt = patientData.totalDebt + totalInterestAddedToPatient;
            batch.update(patientDoc.ref, {
                totalDebt: newTotalDebt,
            });
            updatesCount++;
        }
        // TODO: Queue WhatsApp Reminder 
        // This is a skeleton for the WhatsApp logic
        // e.g., await queueWhatsAppReminder(providerId, patientId, newTotalDebt);
        const finalDebtForMessage = patientData.totalDebt + totalInterestAddedToPatient;
        queueWhatsAppReminder(providerId, patientId, finalDebtForMessage, patientData.name);
    }
    // Commit all updates
    if (updatesCount > 0) {
        console.log(`Committing ${updatesCount} updates (Interests added)`);
        // Warning: Firestore batches have a limit of 500 operations. 
        // For large scale, we should commit every 500 ops.
        await batch.commit();
    }
    console.log("Finished monthlyDebtProcessor");
    return null;
});
/**
 * Skeleton function to handle WhatsApp reminder queues
 */
async function queueWhatsAppReminder(providerId, patientId, totalDebt, patientName) {
    // TODO: Implement actual HTTP call to Meta WhatsApp API
    console.log(`[WhatsApp Engine] Enqueuing reminder for Patient ${patientName} (${patientId}). Debt: $${totalDebt}`);
    // Rules specify writing to communications subcollection/root collection
    await db.collection("communications").add({
        providerId: providerId,
        patientId: patientId,
        type: "whatsapp_reminder",
        status: "pending",
        totalDebtAtThatTime: totalDebt,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        // messageId: ...
    });
}
//# sourceMappingURL=monthlyDebtProcessor.js.map