import * as admin from "firebase-admin";
import { computeTotalDebt, roundCents } from "./debt_calculation";
import { incrementDashboardMetrics } from "./metrics_utils";

export interface DebtRecalculationResult {
  previousDebt: number;
  newDebt: number;
  delta: number;
}

/**
 * Recomputes `totalDebt` from the source of truth (unpaid appointments) inside
 * a transaction and overwrites the stored value.
 *
 * Idempotent by construction: running it N times (trigger retries, duplicate
 * deliveries, out-of-order events) always converges to the same value, unlike
 * the previous delta-based `totalDebt += x` approach.
 *
 * Returns null when the patient doesn't exist (e.g. patient deleted).
 */
export async function recalculatePatientDebt(
  db: admin.firestore.Firestore,
  patientRef: admin.firestore.DocumentReference
): Promise<DebtRecalculationResult | null> {
  return db.runTransaction(async (transaction) => {
    const unpaidQuery = patientRef
      .collection("appointments")
      .where("status", "==", "unpaid");

    const [patientDoc, unpaidSnapshot] = await Promise.all([
      transaction.get(patientRef),
      transaction.get(unpaidQuery),
    ]);

    if (!patientDoc.exists) return null;

    const previousDebt = roundCents(Number(patientDoc.data()?.totalDebt) || 0);
    const newDebt = computeTotalDebt(unpaidSnapshot.docs.map((d) => d.data()));
    const delta = roundCents(newDebt - previousDebt);

    if (delta !== 0) {
      transaction.update(patientRef, { totalDebt: newDebt });
    }

    return { previousDebt, newDebt, delta };
  });
}

/**
 * Recalculates the patient's debt and propagates the correction to the
 * provider dashboard's `totalToCollect`. The dashboard delta derives from the
 * stored-vs-recomputed difference, so a duplicate run yields delta 0.
 */
export async function syncPatientDebt(
  db: admin.firestore.Firestore,
  providerId: string,
  patientId: string
): Promise<DebtRecalculationResult | null> {
  const patientRef = db
    .collection("providers")
    .doc(providerId)
    .collection("patients")
    .doc(patientId);

  const result = await recalculatePatientDebt(db, patientRef);

  if (result && result.delta !== 0) {
    await incrementDashboardMetrics(providerId, { totalToCollect: result.delta });
  }
  return result;
}
