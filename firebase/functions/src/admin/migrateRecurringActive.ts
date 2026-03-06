import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Temporary one-off migration: adds `active: true` to all
 * recurring_appointments that are missing the field.
 *
 * Call via: gcloud functions call admin-migrateRecurringActive --region us-central1 --data "{}"
 * DELETE this function after running.
 */
export const migrateRecurringActive = functions
  .runWith({ timeoutSeconds: 120 })
  .https.onCall(async (_data, _context) => {
    console.log("[migrateRecurringActive] Starting migration...");

    const snapshot = await db.collectionGroup("recurring_appointments").get();

    if (snapshot.empty) {
      console.log("[migrateRecurringActive] No recurring appointments found.");
      return { updated: 0 };
    }

    const batch = db.batch();
    let count = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (data.active === undefined || data.active === null) {
        batch.update(doc.ref, { active: true });
        count++;
        console.log(`[migrateRecurringActive] Will update: ${doc.ref.path}`);
      } else {
        console.log(`[migrateRecurringActive] Already has active=${data.active}: ${doc.ref.path}`);
      }
    }

    if (count > 0) {
      await batch.commit();
      console.log(`[migrateRecurringActive] Migration complete. Updated ${count} documents.`);
    } else {
      console.log("[migrateRecurringActive] All documents already have 'active' field.");
    }

    return { updated: count, total: snapshot.size };
  });
