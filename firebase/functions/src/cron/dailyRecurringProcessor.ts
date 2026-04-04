import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { shouldGenerateToday, toDateKey } from "../utils/dateAndInterest";
import {
  ProviderScheduleData,
  isNonWorkingDay,
  resolveSessionDuration,
} from "../utils/recurring_utils";

const db = admin.firestore();

// ─── Internal helper ────────────────────────────────────────────────────────

/**
 * Generates (or expires) recurring appointments for a single target date.
 *
 * Not exported — consumed by the cron and by `backfillRecurringAppointments`.
 *
 * @param targetDate  The date for which appointments should be generated.
 *                    Time component is ignored (comparisons are date-only).
 * @param db          Firestore instance.
 * @returns           Counts of created, expired, and skipped-holiday docs.
 */
export async function processRecurringForTargetDate(
  targetDate: Date,
  firestoreDb: FirebaseFirestore.Firestore,
): Promise<{
  createdCount: number;
  expiredCount: number;
  skippedHolidaysCount: number;
}> {
  // Normalize to midnight so comparisons are date-only
  const normalizedTarget = new Date(targetDate);
  normalizedTarget.setHours(0, 0, 0, 0);
  const targetDateKey = toDateKey(normalizedTarget);

  const logPrefix = `[processRecurringForTargetDate(${targetDateKey})]`;

  // 1. Fetch all active recurring appointments across all providers/patients
  const snapshot = await firestoreDb
    .collectionGroup("recurring_appointments")
    .where("active", "==", true)
    .get();

  if (snapshot.empty) {
    console.log(`${logPrefix} No active recurring appointments.`);
    return { createdCount: 0, expiredCount: 0, skippedHolidaysCount: 0 };
  }

  console.log(
    `${logPrefix} Processing ${snapshot.size} active recurring appointments`,
  );

  let createdCount = 0;
  let expiredCount = 0;
  let skippedHolidaysCount = 0;

  // Cache to avoid reading provider documents multiple times.
  const providerDaysCache = new Map<string, ProviderScheduleData>();

  for (const recurringDoc of snapshot.docs) {
    try {
      const data = recurringDoc.data();

      const {
        patientId,
        providerId,
        concept,
        defaultAmount,
        frequency,
        defaultSessionDurationMinutes: recurringDurationMinutes,
      } = data;

      const baseDate: Date =
        data.baseDate?.toDate?.() ?? new Date(data.baseDate);
      const endDate: Date | null = data.endDate?.toDate?.() ?? null;
      const lastGeneratedDate: Date | null =
        data.lastGeneratedDate?.toDate?.() ?? null;

      // ── Step 1: Expire if past endDate ──────────────────────────────
      if (endDate && normalizedTarget > endDate) {
        await recurringDoc.ref.update({ active: false });
        expiredCount++;
        console.log(`${logPrefix} Expired recurring ${recurringDoc.id}`);
        continue;
      }

      // ── Step 2: Check if targetDate matches the schedule ─────────────
      if (
        !shouldGenerateToday(
          baseDate,
          frequency,
          normalizedTarget,
          lastGeneratedDate,
        )
      ) {
        continue;
      }

      // Preserve the original time from the baseDate
      const finalDate = new Date(normalizedTarget);
      finalDate.setHours(
        baseDate.getHours(),
        baseDate.getMinutes(),
        baseDate.getSeconds(),
        baseDate.getMilliseconds(),
      );

      // ── Step 2.5: Check if targetDate is a Non-Working Day or Vacation ──
      if (!providerDaysCache.has(providerId)) {
        const providerSnap = await firestoreDb
          .collection("providers")
          .doc(providerId)
          .get();
        const pData = providerSnap.data();
        providerDaysCache.set(providerId, {
          nonWorkingDays: pData?.nonWorkingDays ?? [],
          vacations: pData?.vacations ?? [],
          defaultSessionDurationMinutes:
            pData?.defaultSessionDurationMinutes ?? null,
        });
      }

      const providerData = providerDaysCache.get(providerId)!;

      const { skipped: isSkipped, reason: skipReason } = isNonWorkingDay(
        finalDate,
        providerData,
      );

      if (isSkipped) {
        console.log(
          `${logPrefix} Skipping recurring ${recurringDoc.id} because of ${skipReason}.`,
        );
        skippedHolidaysCount++;

        // CRITICAL: We still need to update lastGeneratedDate to jump over it
        // without creating the appointment.
        await recurringDoc.ref.update({
          lastGeneratedDate:
            admin.firestore.Timestamp.fromDate(normalizedTarget),
        });
        continue;
      }

      // ── Step 2.7: Skip cancelled occurrences ────────────────────────────
      if ((data.cancelledDates ?? []).includes(targetDateKey)) {
        console.log(
          `${logPrefix} Skipping recurring ${recurringDoc.id} on ${targetDateKey} — cancelled by provider.`,
        );
        await recurringDoc.ref.update({
          lastGeneratedDate: admin.firestore.Timestamp.fromDate(normalizedTarget),
        });
        continue;
      }

      // ── Step 3: Idempotency — check if already created for targetDate ─
      const patientRef = recurringDoc.ref.parent.parent!;

      const existingSnapshot = await patientRef
        .collection("appointments")
        .where("recurringAppointmentId", "==", recurringDoc.id)
        .where("dateKey", "==", targetDateKey)
        .limit(1)
        .get();

      if (!existingSnapshot.empty) {
        console.log(
          `${logPrefix} Appointment already exists for ${recurringDoc.id} on ${targetDateKey}`,
        );
        continue;
      }

      // ── Step 4: Create the appointment ──────────────────────────────
      const appointmentRef = patientRef.collection("appointments").doc();

      // Resolve session duration: recurring doc → provider default → fallback 45 min
      const sessionDurationMinutes = resolveSessionDuration(
        recurringDurationMinutes,
        providerDaysCache.get(providerId)?.defaultSessionDurationMinutes,
      );
      const endTime = new Date(
        finalDate.getTime() + sessionDurationMinutes * 60 * 1000,
      );

      await appointmentRef.set({
        patientId,
        providerId,
        recurringAppointmentId: recurringDoc.id,
        concept,
        date: admin.firestore.Timestamp.fromDate(finalDate),
        endTime: admin.firestore.Timestamp.fromDate(endTime),
        dateKey: targetDateKey,
        totalAmount: defaultAmount,
        amountPaid: 0,
        status: "unpaid",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ── Step 5: Update lastGeneratedDate ────────────────────────────
      await recurringDoc.ref.update({
        lastGeneratedDate:
          admin.firestore.Timestamp.fromDate(normalizedTarget),
      });

      createdCount++;
      console.log(
        `${logPrefix} Created appointment for recurring ${recurringDoc.id} on ${targetDateKey}`,
      );
    } catch (error) {
      console.error(
        `${logPrefix} Error processing recurring ${recurringDoc.id}:`,
        error,
      );
    }
  }

  console.log(
    `${logPrefix} Finished. Created: ${createdCount}, Expired: ${expiredCount}, Skipped Holidays: ${skippedHolidaysCount}`,
  );

  return { createdCount, expiredCount, skippedHolidaysCount };
}

// ─── Cron export ─────────────────────────────────────────────────────────────

/**
 * Daily Cron Job — runs every day at 06:00 AM (Buenos Aires).
 *
 * Generates appointments TWO DAYS in advance (targetDate = today + 2).
 *
 * For each active recurring_appointment:
 *   1. If targetDate > endDate → mark as inactive (soft delete).
 *   2. If targetDate matches the schedule → create the appointment
 *      (idempotent: skips if already created for targetDate).
 *   3. Updates `lastGeneratedDate` on the recurring doc.
 *
 * The onAppointmentCreated trigger handles debt & dashboard updates.
 */
export const dailyRecurringProcessor = functions
  .runWith({ maxInstances: 10 })
  .pubsub.schedule("0 6 * * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async (_context) => {
    console.log("[dailyRecurringProcessor] Started");

    const today = new Date();
    // Strip time so comparisons are date-only
    today.setHours(0, 0, 0, 0);

    // Target date = day after tomorrow (generate appointments two days ahead)
    // This gives the message orchestrator buffer time to send reminders
    const targetDate = new Date(today);
    targetDate.setDate(targetDate.getDate() + 2);

    console.log(`[dailyRecurringProcessor] Target date: ${toDateKey(targetDate)}`);

    await processRecurringForTargetDate(targetDate, db);

    return null;
  });
