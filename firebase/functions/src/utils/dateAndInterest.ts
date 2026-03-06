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
    case "monthly": // User requested monthly to be monthly_pattern by default
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

/**
 * Strips the time component from a date, returning YYYY-MM-DD as a string.
 */
export function toDateKey(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

/**
 * Determines whether a recurring appointment should generate an appointment
 * for the given `today` date.
 *
 * Starts iterating from `startFrom` (usually `lastGeneratedDate + 1 step` or
 * `baseDate`) and walks forward using `computeNextDate` until it reaches or
 * passes `today`. If any generated date matches `today`, returns true.
 *
 * @param baseDate - The original start date of the recurring series.
 * @param frequency - One of "weekly", "biweekly", "monthly_pattern", "monthly_28days".
 * @param today - The date to check against.
 * @param lastGeneratedDate - Optional. The last date an appointment was generated.
 *   If provided, iteration starts from the next date after this one.
 * @returns true if today matches a scheduled occurrence.
 */
export function shouldGenerateToday(
  baseDate: Date,
  frequency: string,
  today: Date,
  lastGeneratedDate?: Date | null,
): boolean {
  const todayKey = toDateKey(today);

  // If baseDate itself is today, it's a match
  if (toDateKey(baseDate) === todayKey) return true;

  // Start iterating from lastGeneratedDate (next step) or baseDate
  let current: Date;
  if (lastGeneratedDate) {
    current = computeNextDate(lastGeneratedDate, frequency);
  } else {
    current = new Date(baseDate);
  }

  // Safety: limit iterations (max ~5 years of weekly = ~260)
  const MAX_ITERATIONS = 300;
  for (let i = 0; i < MAX_ITERATIONS; i++) {
    const currentKey = toDateKey(current);

    if (currentKey === todayKey) return true;

    // If we've passed today, no match
    if (current > today) return false;

    current = computeNextDate(current, frequency);
  }

  return false;
}
