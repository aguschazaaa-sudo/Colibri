import * as admin from "firebase-admin";

/**
 * Represents a vacation period with start and end dates.
 * Dates may be Firestore Timestamps (from the Admin SDK) or ISO strings.
 */
export interface VacationPeriod {
  startDate: admin.firestore.Timestamp | string;
  endDate: admin.firestore.Timestamp | string;
}

/**
 * Provider schedule data needed to determine non-working days and vacations.
 */
export interface ProviderScheduleData {
  nonWorkingDays: string[];
  vacations: VacationPeriod[];
  defaultSessionDurationMinutes: number | null;
}

/**
 * Buenos Aires UTC offset in milliseconds (UTC-3).
 */
const BA_OFFSET_MS = 3 * 60 * 60 * 1000;

/**
 * Converts a Timestamp-or-string value to a Date.
 */
function toDate(value: admin.firestore.Timestamp | string): Date {
  if (typeof value === "string") return new Date(value);
  // Firestore Timestamp has .toDate()
  return (value as admin.firestore.Timestamp).toDate();
}

/**
 * Checks whether `finalDate` falls on a non-working day or during a vacation
 * period for the given provider, using Buenos Aires timezone alignment (UTC-3).
 *
 * @param finalDate  The appointment date/time (with time preserved from baseDate).
 * @param providerData  The provider's schedule data (nonWorkingDays, vacations).
 * @returns `{ skipped: true, reason }` if the date should be skipped, otherwise `{ skipped: false, reason: "" }`.
 */
export function isNonWorkingDay(
  finalDate: Date,
  providerData: ProviderScheduleData,
): { skipped: boolean; reason: string } {
  const { nonWorkingDays, vacations } = providerData;

  // Align the date to Buenos Aires time (UTC-3).
  // An appointment at 23:00 BA time is 02:00 UTC the next day —
  // without this offset the holiday check would use the wrong calendar day.
  const baDateCheck = new Date(finalDate.getTime() - BA_OFFSET_MS);
  const targetMMDD_BA = `${String(baDateCheck.getUTCMonth() + 1).padStart(2, "0")}-${String(baDateCheck.getUTCDate()).padStart(2, "0")}`;

  // Check non-working days (MM-DD format)
  if (nonWorkingDays.includes(targetMMDD_BA)) {
    return { skipped: true, reason: `holiday ${targetMMDD_BA}` };
  }

  // Check vacation periods (also using BA timezone alignment)
  for (const v of vacations) {
    const start = toDate(v.startDate);
    const end = toDate(v.endDate);

    const startBA = new Date(start.getTime() - BA_OFFSET_MS);
    const endBA = new Date(end.getTime() - BA_OFFSET_MS);

    startBA.setUTCHours(0, 0, 0, 0);
    endBA.setUTCHours(23, 59, 59, 999);

    const baDateCheckMidnight = new Date(baDateCheck);
    baDateCheckMidnight.setUTCHours(0, 0, 0, 0);

    if (baDateCheckMidnight >= startBA && baDateCheckMidnight <= endBA) {
      return { skipped: true, reason: "vacation period" };
    }
  }

  return { skipped: false, reason: "" };
}

/**
 * Resolves the effective session duration in minutes using the following
 * priority: recurring document value -> provider default -> 45 min fallback.
 *
 * The result is clamped to the range [1, 480] (8 hours max).
 * If the resolved value is not a valid positive number within range, falls
 * back to 45 minutes.
 *
 * @param recurringDurationMinutes  Duration stored on the recurring appointment doc.
 * @param providerDefaultMinutes    Default duration from the provider profile.
 * @returns A safe integer duration in minutes.
 */
export function resolveSessionDuration(
  recurringDurationMinutes: number | undefined | null,
  providerDefaultMinutes: number | undefined | null,
): number {
  const rawDuration = recurringDurationMinutes ?? providerDefaultMinutes ?? 45;
  return typeof rawDuration === "number" && rawDuration > 0 && rawDuration <= 480
    ? rawDuration
    : 45;
}
