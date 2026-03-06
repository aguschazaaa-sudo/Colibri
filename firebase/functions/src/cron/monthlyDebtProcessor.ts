import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { MONTHLY_INTEREST_RATE, calculateInterest } from "../utils/dateAndInterest";
import { incrementDashboardMetrics, resetMonthlyRevenue } from "../utils/metrics_utils";

const db = admin.firestore();

/**
 * Cron Job that runs on the 28th of every month at 15:00.
 * 1. Finds unpaid appointments older than 1 month.
 * 2. Applies monthly interest to the remaining amount.
 * 3. Updates Patient's totalDebt.
 * 4. Triggers WhatsApp reminder logic.
 */
export const monthlyDebtProcessor = functions
  .runWith({ maxInstances: 10 })
  .pubsub.schedule("0 15 28 * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async (context) => {
    console.log("Started monthlyDebtProcessor");

    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    // Use collectionGroup("patients") to find all patients across all providers
    // that currently have debt, without needing to scan each provider individually.
    const patientsWithDebtSnapshot = await db.collectionGroup("patients")
      .where("totalDebt", ">", 0)
      .get();
      
    if (patientsWithDebtSnapshot.empty) {
        console.log("No patients with debt found.");
        return null;
    }

    console.log(`Processing debt for ${patientsWithDebtSnapshot.size} patients`);

    const batch = db.batch();
    let updatesCount = 0;

    // Track interest added per provider: { providerId -> totalInterest }
    const providerInterestMap = new Map<string, number>();

    for (const patientDoc of patientsWithDebtSnapshot.docs) {
      const patientId = patientDoc.id;
      const patientData = patientDoc.data();
      const providerId = patientData.providerId;

      // Use patientDoc.ref to build the subcollection path — it already contains
      // the correct path: providers/{providerId}/patients/{patientId}
      const unpaidAppointmentsSnapshot = await patientDoc.ref
        .collection("appointments")
        .where("status", "==", "unpaid")
        .get();

      let totalInterestAddedToPatient = 0;

      for (const appDoc of unpaidAppointmentsSnapshot.docs) {
        const appData = appDoc.data();
        const appDate: admin.firestore.Timestamp = appData.date;

        // Check if appointment is older than 1 month
        if (appDate.toDate() < oneMonthAgo) {
          const pendingAmount = appData.totalAmount - (appData.amountPaid || 0);
          
          if (pendingAmount > 0) {
            // Apply compound interest
            const interestAmount = calculateInterest(pendingAmount, MONTHLY_INTEREST_RATE);
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
        // Accumulate interest per provider for dashboard update
        const prev = providerInterestMap.get(providerId) ?? 0;
        providerInterestMap.set(providerId, prev + totalInterestAddedToPatient);
      }

      // Queue WhatsApp Reminder
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

    // For each provider: reset monthlyRevenue (new cycle) AND increment
    // totalToCollect by the interest their patients just accrued.
    const dashboardPromises = Array.from(providerInterestMap.entries()).map(
      ([pid, interestAdded]) =>
        Promise.all([
          resetMonthlyRevenue(pid),
          incrementDashboardMetrics(pid, { totalToCollect: interestAdded }),
        ])
    );
    await Promise.all(dashboardPromises);
    console.log(`[monthlyDebtProcessor] Updated dashboard for ${providerInterestMap.size} provider(s).`);

    console.log("Finished monthlyDebtProcessor");
    return null;
});

/**
 * Skeleton function to handle WhatsApp reminder queues
 */
async function queueWhatsAppReminder(providerId: string, patientId: string, totalDebt: number, patientName: string) {
    console.log(`[WhatsApp Engine] Enqueuing reminder for Patient ${patientName} (${patientId}). Debt: $${totalDebt}`);
    
    await db.collection("communications").add({
        providerId: providerId,
        patientId: patientId,
        type: "whatsapp_reminder",
        status: "pending",
        totalDebtAtThatTime: totalDebt,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
