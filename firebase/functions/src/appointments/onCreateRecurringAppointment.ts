import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { shouldGenerateToday, toDateKey } from "../utils/dateAndInterest";

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
    const { concept, defaultAmount, frequency } = data;
    
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

    const targetDates = [today, tomorrow];
    let generatedCount = 0;

    // Fetch provider settings once
    const db = getDb();
    const providerSnap = await db.collection("providers").doc(providerId).get();
    const pData = providerSnap.data();
    const nonWorkingDays: string[] = pData?.nonWorkingDays ?? [];
    const vacations: any[] = pData?.vacations ?? [];

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

      // To check holidays correctly, we must align the date to Buenos Aires time (UTC-3).
      // Otherwise, an appointment at 23:00 BA time is 02:00 UTC the next day, which would miss the holiday check!
      const baDateCheck = new Date(finalDate.getTime() - (3 * 60 * 60 * 1000));
      const targetMMDD_BA = `${String(baDateCheck.getUTCMonth() + 1).padStart(2, "0")}-${String(baDateCheck.getUTCDate()).padStart(2, "0")}`;
      
      let isSkipped = false;
      let skipReason = "";

      if (nonWorkingDays.includes(targetMMDD_BA)) {
        isSkipped = true;
        skipReason = `holiday ${targetMMDD_BA}`;
      } else {
        // Check vacations (also using BA timezone alignment)
        for (const v of vacations) {
          const start = v.startDate?.toDate?.() ?? new Date(v.startDate);
          const end = v.endDate?.toDate?.() ?? new Date(v.endDate);
          
          // Move start/end to UTC-3 midnight to compare with baDateCheck
          const startBA = new Date(start.getTime() - (3 * 60 * 60 * 1000));
          const endBA = new Date(end.getTime() - (3 * 60 * 60 * 1000));
          
          startBA.setUTCHours(0, 0, 0, 0);
          endBA.setUTCHours(23, 59, 59, 999);
          
          const baDateCheckMidnight = new Date(baDateCheck);
          baDateCheckMidnight.setUTCHours(0,0,0,0);
          
          if (baDateCheckMidnight >= startBA && baDateCheckMidnight <= endBA) {
            isSkipped = true;
            skipReason = `vacation period`;
            break;
          }
        }
      }

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
      
      const appointmentRef = patientRef.collection("appointments").doc();

      await appointmentRef.set({
        patientId,
        providerId,
        recurringAppointmentId: recurringId,
        concept,
        date: admin.firestore.Timestamp.fromDate(finalDate),
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
