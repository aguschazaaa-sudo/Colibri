/**
 * Pure utility functions for date computation and interest calculation.
 * Extracted from Cloud Functions for testability.
 */

// Default interest rate: 5% per month (Compound)
export const MONTHLY_INTEREST_RATE = 0.05;

/**
 * Computes the next date based on a frequency pattern.
 */
export function computeNextDate(date: Date, frequency: string): Date {
  const next = new Date(date);
  switch (frequency) {
    case "weekly":
      next.setDate(next.getDate() + 7);
      break;
    case "biweekly":
      next.setDate(next.getDate() + 14);
      break;
    case "monthly_28days":
      next.setDate(next.getDate() + 28);
      break;
    case "monthly_pattern": {
      // "Nth Weekday of the month" logic
      const targetDayOfWeek = date.getDay();
      const nThOccurrence = Math.ceil(date.getDate() / 7);

      const targetMonth = (date.getMonth() + 1) % 12;
      const targetYear = date.getMonth() === 11 ? date.getFullYear() + 1 : date.getFullYear();

      next.setFullYear(targetYear, targetMonth, 1);

      // Find the first occurrence of the target day of week in the new month
      let daysOffset = targetDayOfWeek - next.getDay();
      if (daysOffset < 0) daysOffset += 7;

      // Move to the Nth occurrence
      next.setDate(1 + daysOffset + (nThOccurrence - 1) * 7);

      // Edge case: if the 5th occurrence spills into the NEXT month, fallback to 4th
      if (next.getMonth() !== targetMonth) {
        next.setDate(next.getDate() - 7);
      }
      break;
    }
    default:
      throw new Error(`Unknown frequency: ${frequency}`);
  }
  return next;
}

/**
 * Generates a series of dates for recurring appointments.
 */
export function generateRecurringDates(
  baseDate: Date,
  frequency: string,
  occurrences: number
): Date[] {
  const dates: Date[] = [];
  let current = new Date(baseDate);
  for (let i = 0; i < occurrences; i++) {
    dates.push(new Date(current));
    current = computeNextDate(current, frequency);
  }
  return dates;
}

/**
 * Calculates compound interest on a pending amount.
 */
export function calculateInterest(
  pendingAmount: number,
  rate: number = MONTHLY_INTEREST_RATE
): number {
  return pendingAmount * rate;
}

/**
 * Checks if a date is older than N months from a reference date.
 */
export function isOlderThanMonths(date: Date, months: number, referenceDate: Date = new Date()): boolean {
  const threshold = new Date(referenceDate);
  threshold.setMonth(threshold.getMonth() - months);
  return date < threshold;
}
