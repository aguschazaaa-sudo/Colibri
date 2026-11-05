/**
 * Pure debt computation. No Firestore dependencies → fully unit-testable.
 *
 * Invariant enforced across the backend:
 *   patient.totalDebt === Σ max(0, totalAmount - amountPaid) over appointments with status "unpaid"
 *
 * This is exactly what the client renders in "Turnos sin pagar", so the
 * "Deuda Total" card and the list can never diverge again.
 */

export interface DebtSource {
  status?: string;
  totalAmount?: number;
  amountPaid?: number;
}

/** Rounds to cents to avoid floating point noise accumulating in the ledger. */
export function roundCents(value: number): number {
  return Math.round(value * 100) / 100;
}

export function pendingDebtOf(app: DebtSource): number {
  if (app.status !== "unpaid") return 0;
  const total = Number(app.totalAmount) || 0;
  const paid = Number(app.amountPaid) || 0;
  return Math.max(0, total - paid);
}

export function computeTotalDebt(appointments: DebtSource[]): number {
  return roundCents(
    appointments.reduce((acc, app) => acc + pendingDebtOf(app), 0)
  );
}

/** Fields whose change can alter a patient's debt. */
const DEBT_FIELDS: (keyof DebtSource)[] = ["status", "totalAmount", "amountPaid"];

/**
 * Returns true when a write (create / update / delete) can change the debt.
 * Lets the onWrite trigger skip no-op updates (e.g. concept or date edits).
 */
export function affectsDebt(
  before: DebtSource | undefined,
  after: DebtSource | undefined
): boolean {
  if (!before || !after) return true; // create or delete
  return DEBT_FIELDS.some((field) => before[field] !== after[field]);
}
