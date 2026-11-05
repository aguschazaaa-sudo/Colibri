import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { MONTHLY_INTEREST_RATE, calculateInterest } from "../utils/dateAndInterest";
import { incrementDashboardMetrics, resetMonthlyRevenue, saveMonthlySnapshot } from "../utils/metrics_utils";
import { BatchWriter } from "../utils/batch_utils";

const db = admin.firestore();

/**
 * Cron Job that runs on the 1st of every month at 15:00.
 * 1. Finds overdue unpaid appointments.
 * 2. Applies monthly interest to appointments older than 1 month.
 * 3. Updates Patient's totalDebt.
 *
 * WhatsApp payment reminders are handled separately by monthlyDebtNotifier
 * (runs at 16:00, 1 hour after this job).
 */
export const monthlyDebtProcessor = functions
  .runWith({ maxInstances: 10 })
  .pubsub.schedule("0 15 1 * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async () => {
    functions.logger.info("[monthlyDebtProcessor] Started");

    const now = new Date();
    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    const [basicSnap, premiumSnap, trialSnap] = await Promise.all([
      db
        .collection("providers")
        .where("subscriptionStatus", "==", "active")
        .where("plan", "==", "basic")
        .get(),
      db
        .collection("providers")
        .where("subscriptionStatus", "==", "active")
        .where("plan", "==", "premium")
        .get(),
      db
        .collection("providers")
        .where("subscriptionStatus", "==", "active")
        .where("plan", "==", "trial")
        .get(),
    ]);

    const allProviderDocs = [
      ...basicSnap.docs,
      ...premiumSnap.docs,
      ...trialSnap.docs,
    ];

    if (allProviderDocs.length === 0) {
      functions.logger.info("[monthlyDebtProcessor] No active providers found.");
      return null;
    }

    const activeProviderIds = new Set<string>(
      allProviderDocs.map((d) => d.id)
    );

    const nowTs = admin.firestore.Timestamp.fromDate(now);
    const unpaidSnapshot = await db
      .collectionGroup("appointments")
      .where("status", "==", "unpaid")
      .where("date", "<=", nowTs)
      .get();

    const batchWriter = new BatchWriter();

    // Track interest added per provider: { providerId -> totalInterest }
    const providerInterestMap = new Map<string, number>();

    type PatientAgg = {
      patientRef: FirebaseFirestore.DocumentReference;
      patientId: string;
      providerId: string;
      overdueDebt: number;
      interestAdded: number;
    };

    const patientAggMap = new Map<string, PatientAgg>();

    for (const appDoc of unpaidSnapshot.docs) {
      const appData = appDoc.data();
      const providerId = appData.providerId as string | undefined;
      if (!providerId || !activeProviderIds.has(providerId)) {
        continue;
      }

      const appDate: admin.firestore.Timestamp | undefined = appData.date;
      if (!appDate?.toDate) continue;
      const appDateValue = appDate.toDate();
      if (appDateValue > now) continue;

      const totalAmount: number = appData.totalAmount || 0;
      const amountPaid: number = appData.amountPaid || 0;
      const pendingAmount = totalAmount - amountPaid;
      if (pendingAmount <= 0) continue;

      const patientRef = appDoc.ref.parent.parent;
      if (!patientRef) continue;

      const key = patientRef.path;
      const existing =
        patientAggMap.get(key) ??
        ({
          patientRef,
          patientId: patientRef.id,
          providerId,
          overdueDebt: 0,
          interestAdded: 0,
        } as PatientAgg);

      existing.overdueDebt += pendingAmount;

      if (appDateValue < oneMonthAgo) {
        const interestAmount = calculateInterest(
          pendingAmount,
          MONTHLY_INTEREST_RATE
        );
        if (interestAmount > 0) {
          const newTotalAmount = totalAmount + interestAmount;
          await batchWriter.update(appDoc.ref, {
            totalAmount: newTotalAmount,
            _functionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          existing.interestAdded += interestAmount;
          existing.overdueDebt += interestAmount;

          const prev = providerInterestMap.get(providerId) ?? 0;
          providerInterestMap.set(providerId, prev + interestAmount);
        }
      }

      patientAggMap.set(key, existing);
    }

    for (const agg of patientAggMap.values()) {
      if (agg.interestAdded > 0) {
        await batchWriter.update(agg.patientRef, {
          totalDebt: admin.firestore.FieldValue.increment(agg.interestAdded),
        });
      }
    }

    await batchWriter.flush();

    // For each active provider: save a monthly snapshot, reset monthlyRevenue
    // (new cycle) and — if there was interest — increment totalToCollect.
    // Iterating over ALL active providers (not just providerInterestMap) ensures
    // monthlyRevenue is always reset and a snapshot is always captured, even
    // for providers whose patients had no overdue debt this cycle.
    for (const doc of allProviderDocs) {
      const pid = doc.id;
      await saveMonthlySnapshot(pid);
      await resetMonthlyRevenue(pid);
      const interest = providerInterestMap.get(pid) ?? 0;
      if (interest > 0) {
        await incrementDashboardMetrics(pid, { totalToCollect: interest });
      }
    }
    functions.logger.info("[monthlyDebtProcessor] Updated dashboard", {
      providers: allProviderDocs.length,
    });

    functions.logger.info("[monthlyDebtProcessor] Finished");
    return null;
  });
