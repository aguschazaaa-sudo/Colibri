import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { shouldGenerateToday, toDateKey } from "../utils/dateAndInterest";
import {
  ProviderScheduleData,
  isNonWorkingDay,
  resolveSessionDuration,
} from "../utils/recurring_utils";

const getDb = () => admin.firestore();

export const onCreateRecurringAppointment = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/recurring_appointments/{recurringId}",
  )
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data || !data.active) return;

    const { providerId, patientId, recurringId } = context.params;
    const { concept, defaultAmount, frequency, defaultSessionDurationMinutes: recurringDurationMinutes } = data;
    
    const baseDate: Date = data.baseDate?.toDate?.() ?? new Date(data.baseDate);
    const endDate: Date | null = data.endDate?.toDate?.() ?? null;
    
    // Check if we need to generate for "today" or "tomorrow"
    // We use Buenos Aires timezone logic similar to the cron job.
    // Use UTC offset for BA (-3 hours) if we want strictly local, 
    // but the cron uses new Date() and just sets hours to 0. 
    // We do the same to match the cron's execution context.
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Also cover today+2: the cron generates 2 days ahead at 06:00 AM,
    // so if this trigger fires after the cron ran, today+2 would be missed
    // without this third target date.
    const dayAfterTomorrow = new Date(today);
    dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 2);

    const targetDates = [today, tomorrow, dayAfterTomorrow];
    let generatedCount = 0;

    // Fetch provider settings once
    const db = getDb();
    const providerSnap = await db.collection("providers").doc(providerId).get();
    const pData = providerSnap.data();
    const providerSchedule: ProviderScheduleData = {
      nonWorkingDays: pData?.nonWorkingDays ?? [],
      vacations: pData?.vacations ?? [],
      defaultSessionDurationMinutes: pData?.defaultSessionDurationMinutes ?? null,
    };

    for (const targetDate of targetDates) {
      if (endDate && targetDate > endDate) continue;

      if (!shouldGenerateToday(baseDate, frequency, targetDate, null)) {
        continue;
      }

      // Preserve the original time from the baseDate
      const finalDate = new Date(targetDate);
      finalDate.setHours(
        baseDate.getHours(),
        baseDate.getMinutes(),
        baseDate.getSeconds(),
        baseDate.getMilliseconds()
      );

      const { skipped: isSkipped, reason: skipReason } = isNonWorkingDay(finalDate, providerSchedule);

      if (isSkipped) {
        console.log(`[onCreateRecurringAppointment] Skipping eager generation for ${recurringId} on ${toDateKey(targetDate)} because of ${skipReason}.`);
        // We still need to update lastGeneratedDate so the cron doesn't try again
        await snap.ref.update({
          lastGeneratedDate: admin.firestore.Timestamp.fromDate(targetDate),
        });
        continue;
      }

      // ── Create the appointment
      // We still use targetDateKey as deduplication key, which is fine as it's internally consistent
      const patientRef = snap.ref.parent.parent!;
      const targetDateKey = toDateKey(targetDate);

      // Resolve session duration: recurring doc → provider default → fallback 45 min
      const sessionDurationMinutes = resolveSessionDuration(
        recurringDurationMinutes,
        providerSchedule.defaultSessionDurationMinutes,
      );
      const endTime = new Date(
        finalDate.getTime() + sessionDurationMinutes * 60 * 1000,
      );

      const appointmentRef = patientRef.collection("appointments").doc();

      await appointmentRef.set({
        patientId,
        providerId,
        recurringAppointmentId: recurringId,
        concept,
        date: admin.firestore.Timestamp.fromDate(finalDate),
        endTime: admin.firestore.Timestamp.fromDate(endTime),
        dateKey: targetDateKey,
        totalAmount: defaultAmount,
        amountPaid: 0,
        status: "unpaid",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update lastGeneratedDate on the recurring document
      await snap.ref.update({
        lastGeneratedDate: admin.firestore.Timestamp.fromDate(targetDate),
      });

      generatedCount++;
      console.log(`[onCreateRecurringAppointment] Eagerly created appointment for ${recurringId} on ${targetDateKey}`);
    }

    if (generatedCount === 0) {
      console.log(`[onCreateRecurringAppointment] No eager appointments generated for ${recurringId}.`);
    } else {
      console.log(`[onCreateRecurringAppointment] Eagerly generated ${generatedCount} appointments for ${recurringId}.`);
    }
  });
