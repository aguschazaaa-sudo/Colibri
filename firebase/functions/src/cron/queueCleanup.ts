import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

const BATCH_SIZE = 500;

/**
 * Daily Cron Job — runs every day at 03:00 AM (Buenos Aires).
 *
 * Cleans up old documents from the `message_queue` collection
 * to prevent unbounded growth.
 *
 * Targets:
 *   - Documents with status "sent", "expired", "duplicate", or "cancelled" older than 7 days.
 *   - Documents with status "failed" that have exhausted retries (attempts >= 3)
 *     and are older than 7 days.
 *   - Documents with status "processing" and processedAt older than 48h
 *     (stuck items where sendWhatsAppReminder failed without updating status).
 *
 * Documents with status "queued" are never deleted regardless of age.
 * Batches are limited to 500 operations to respect Firestore limits.
 */
export const queueCleanup = functions
  .runWith({ maxInstances: 1 })
  .pubsub.schedule("0 3 * * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async () => {
    const sevenDaysCutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );
    const fortyEightHoursCutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 48 * 60 * 60 * 1000)
    );

    const terminalStatusQuery = db
      .collection("message_queue")
      .where("status", "in", ["sent", "expired", "duplicate", "cancelled"])
      .where("createdAt", "<", sevenDaysCutoff)
      .limit(500);

    const failedQuery = db
      .collection("message_queue")
      .where("status", "==", "failed")
      .where("attempts", ">=", 3)
      .where("createdAt", "<", sevenDaysCutoff)
      .limit(500);

    const stuckProcessingQuery = db
      .collection("message_queue")
      .where("status", "==", "processing")
      .where("processedAt", "<", fortyEightHoursCutoff)
      .limit(500);

    const [terminalSnap, failedSnap, stuckSnap] = await Promise.all([
      terminalStatusQuery.get(),
      failedQuery.get(),
      stuckProcessingQuery.get(),
    ]);

    const allDocs = [...terminalSnap.docs, ...failedSnap.docs, ...stuckSnap.docs];

    if (allDocs.length === 0) {
      functions.logger.info("[queueCleanup] No stale documents found");
      return null;
    }

    // Commit in chunks of BATCH_SIZE to respect Firestore's 500-operation limit
    let totalDeleted = 0;
    for (let i = 0; i < allDocs.length; i += BATCH_SIZE) {
      const chunk = allDocs.slice(i, i + BATCH_SIZE);
      const batch = db.batch();
      for (const doc of chunk) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      totalDeleted += chunk.length;
    }

    functions.logger.info(
      `[queueCleanup] Deleted ${totalDeleted} stale documents`
    );

    return null;
  });
