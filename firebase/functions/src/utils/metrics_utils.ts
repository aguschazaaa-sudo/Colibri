import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Returns a reference to the dashboard metrics document for a provider.
 * Document path: providers/{providerId}/metrics/dashboard
 */
export function getDashboardRef(providerId: string) {
  return db
    .collection("providers")
    .doc(providerId)
    .collection("metrics")
    .doc("dashboard");
}

/**
 * Atomically increments or decrements the dashboard metric fields.
 *
 * @param providerId - The authenticated provider's UID.
 * @param delta - Object with numeric deltas to apply.
 *   - `totalToCollect`: amount to add (use negative to subtract)
 *   - `monthlyRevenue`: amount to add
 *
 * Uses `FieldValue.increment` for atomic concurrency-safe updates,
 * and `merge: true` so the document is auto-created on first use.
 */
export async function incrementDashboardMetrics(
  providerId: string,
  delta: {
    totalToCollect?: number;
    monthlyRevenue?: number;
  }
): Promise<void> {
  const ref = getDashboardRef(providerId);

  const updates: Record<string, admin.firestore.FieldValue | Date> = {
    lastUpdated: admin.firestore.FieldValue.serverTimestamp() as unknown as Date,
  };

  if (delta.totalToCollect !== undefined) {
    updates["totalToCollect"] = admin.firestore.FieldValue.increment(
      delta.totalToCollect
    );
  }
  if (delta.monthlyRevenue !== undefined) {
    updates["monthlyRevenue"] = admin.firestore.FieldValue.increment(
      delta.monthlyRevenue
    );
  }

  await ref.set(updates, { merge: true });
}

/**
 * Resets monthlyRevenue to 0 at the start of a new billing cycle.
 * Called by the 28th-of-month cron job.
 */
export async function resetMonthlyRevenue(providerId: string): Promise<void> {
  const ref = getDashboardRef(providerId);
  await ref.set(
    {
      monthlyRevenue: 0,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}
