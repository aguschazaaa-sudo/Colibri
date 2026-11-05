import * as functions from "firebase-functions";
import * as admin from "firebase-admin";



const db = admin.firestore();

/**
 * Daily cron to activate scheduled appointments once their date has passed.
 * It converts them to unpaid (or liquidated if balance covers it) and updates
 * patient totals accordingly.
 */
export const dailyScheduledActivator = functions
  .runWith({ maxInstances: 1 })
  .pubsub.schedule("0 * * * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async () => {
    const now = new Date();
    const nowTs = admin.firestore.Timestamp.fromDate(now);

    const snapshot = await db
      .collectionGroup("appointments")
      .where("status", "==", "scheduled")
      .where("date", "<=", nowTs)
      .get();

    if (snapshot.empty) {
      return null;
    }

    const concurrencyLimit = 10;
    let index = 0;
    let totalActivated = 0;

    async function worker() {
      while (index < snapshot.docs.length) {
        const doc = snapshot.docs[index++];
        const data = doc.data();
        if (data.status !== "scheduled") continue;

        const totalAmount: number = data.totalAmount || 0;
        if (totalAmount <= 0) continue;

        // Simply update the status to "unpaid"
        // The `onAppointmentUpdated` trigger will take care of
        // applying any existing patient balance, increasing debt, and updating metrics.
        await doc.ref.update({
          status: "unpaid"
        });

        totalActivated++;
      }
    }

    const workers = Array.from({ length: concurrencyLimit }, () => worker());
    await Promise.all(workers);

    functions.logger.info("[dailyScheduledActivator] Activated", {
      totalActivated,
    });
    return null;
  });
