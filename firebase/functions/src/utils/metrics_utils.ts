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
 * Numeric deltas applicable to the dashboard metrics document.
 *   - `totalToCollect`: amount to add (negative to subtract).
 *   - `monthlyRevenue`: amount to add (negative to subtract).
 */
export interface DashboardDelta {
  totalToCollect?: number;
  monthlyRevenue?: number;
}

/**
 * Builds the `set(..., { merge: true })` payload for a dashboard delta.
 * Only fields with a finite, non-zero delta are included.
 * Returns `null` when there is nothing to write.
 */
function buildDashboardUpdate(
  delta: DashboardDelta
): Record<string, admin.firestore.FieldValue> | null {
  const updates: Record<string, admin.firestore.FieldValue> = {};

  const toCollect = delta.totalToCollect;
  if (typeof toCollect === "number" && isFinite(toCollect) && toCollect !== 0) {
    updates["totalToCollect"] = admin.firestore.FieldValue.increment(toCollect);
  }
  const revenue = delta.monthlyRevenue;
  if (typeof revenue === "number" && isFinite(revenue) && revenue !== 0) {
    updates["monthlyRevenue"] = admin.firestore.FieldValue.increment(revenue);
  }

  if (Object.keys(updates).length === 0) return null;

  updates["lastUpdated"] = admin.firestore.FieldValue.serverTimestamp();
  return updates;
}

/**
 * Applies a dashboard metrics delta INSIDE an existing Firestore transaction.
 *
 * This is the only correct way for ledger triggers (appointments / payments)
 * to keep `totalToCollect` in sync with `sum(patient.totalDebt)`: the patient
 * write and the dashboard increment commit atomically, so they can never
 * diverge, and a transaction retry re-computes the delta from scratch instead
 * of double-counting it.
 *
 * It is a blind write (`set` + `merge` + `FieldValue.increment`, no read), so
 * it adds no read contention to the transaction. Must be called after all
 * `transaction.get()` calls (Firestore requires reads before writes).
 *
 * No-op when every delta is zero / missing / non-finite.
 *
 * @param transaction - The running Firestore transaction.
 * @param providerId - The provider that owns the dashboard document.
 * @param delta - Exact deltas to apply. For `totalToCollect`, callers must pass
 *   `newTotalDebt - currentTotalDebt` using the exact (post-clamp) value they
 *   write to the patient document.
 */
export function applyDashboardDeltaInTx(
  transaction: admin.firestore.Transaction,
  providerId: string,
  delta: DashboardDelta
): void {
  const updates = buildDashboardUpdate(delta);
  if (!updates) return;
  transaction.set(getDashboardRef(providerId), updates, { merge: true });
}

/**
 * Atomically increments or decrements the dashboard metric fields, OUTSIDE
 * of any transaction.
 *
 * Ledger triggers must NOT use this (see {@link applyDashboardDeltaInTx}).
 * It remains for batch jobs that update patient docs via `FieldValue.increment`
 * (e.g. the monthly interest processor).
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

/**
 * Saves a snapshot of the current monthlyRevenue before resetting it.
 *
 * Idempotent: uses set() with the YYYY-MM document key so re-runs
 * on the same month overwrite rather than duplicate.
 *
 * Path: providers/{providerId}/metrics/dashboard/monthly_snapshots/{YYYY-MM}
 *
 * @param providerId - The authenticated provider's UID.
 */
export async function saveMonthlySnapshot(providerId: string): Promise<void> {
  const dashRef = getDashboardRef(providerId);
  const dashSnap = await dashRef.get();
  const data = dashSnap.data();
  const monthlyRevenue: number =
    (data?.monthlyRevenue as number | undefined) ?? 0;
  const totalDebt: number = (data?.totalToCollect as number | undefined) ?? 0;

  // The snapshot is for the month that just ended (previous month).
  // Use Buenos Aires timezone for consistency with the cron schedule.
  const nowBA = new Date(
    new Date().toLocaleString("en-US", {
      timeZone: "America/Argentina/Buenos_Aires",
    })
  );
  // Go to previous month by subtracting 1 day — the last day of the previous month
  const lastDayPrevMonth = new Date(nowBA.getFullYear(), nowBA.getMonth(), 0);
  const year = lastDayPrevMonth.getFullYear();
  const monthIndex = lastDayPrevMonth.getMonth(); // 0-11
  const month = `${year}-${String(monthIndex + 1).padStart(2, "0")}`;

  const snapshotRef = dashRef.collection("monthly_snapshots").doc(month);
  await snapshotRef.set({
    month,
    totalRevenue: monthlyRevenue,
    totalDebt,
    year,
    monthIndex,
    savedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
