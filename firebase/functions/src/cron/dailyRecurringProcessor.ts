import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { shouldGenerateToday, toDateKey } from "../utils/dateAndInterest";

const db = admin.firestore();

/**
 * Daily Cron Job — runs every day at 06:00 AM (Buenos Aires).
 *
 * Generates appointments ONE DAY in advance (targetDate = tomorrow).
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

    // Target date = tomorrow (generate appointments one day ahead)
    const targetDate = new Date(today);
    targetDate.setDate(targetDate.getDate() + 1);
    const targetDateKey = toDateKey(targetDate);

    console.log(`[dailyRecurringProcessor] Target date: ${targetDateKey}`);

    // 1. Fetch all active recurring appointments across all providers/patients
    const snapshot = await db
      .collectionGroup("recurring_appointments")
      .where("active", "==", true)
      .get();

    if (snapshot.empty) {
      console.log(
        "[dailyRecurringProcessor] No active recurring appointments.",
      );
      return null;
    }

    console.log(
      `[dailyRecurringProcessor] Processing ${snapshot.size} active recurring appointments`,
    );

    let createdCount = 0;
    let expiredCount = 0;
    let skippedHolidaysCount = 0;

    // Cache to avoid reading provider documents multiple times.
    const providerDaysCache = new Map<string, { nonWorkingDays: string[], vacations: any[] }>();

    for (const recurringDoc of snapshot.docs) {
      try {
        const data = recurringDoc.data();

        const { patientId, providerId, concept, defaultAmount, frequency } =
          data;

        const baseDate: Date =
          data.baseDate?.toDate?.() ?? new Date(data.baseDate);
        const endDate: Date | null = data.endDate?.toDate?.() ?? null;
        const lastGeneratedDate: Date | null =
          data.lastGeneratedDate?.toDate?.() ?? null;

        // ── Step 1: Expire if past endDate ──────────────────────────────
        if (endDate && targetDate > endDate) {
          await recurringDoc.ref.update({ active: false });
          expiredCount++;
          console.log(
            `[dailyRecurringProcessor] Expired recurring ${recurringDoc.id}`,
          );
          continue;
        }

        // ── Step 2: Check if targetDate matches the schedule ─────────────
        if (
          !shouldGenerateToday(
            baseDate,
            frequency,
            targetDate,
            lastGeneratedDate,
          )
        ) {
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

        // ── Step 2.5: Check if targetDate is a Non-Working Day or Vacation ───────────
        if (!providerDaysCache.has(providerId)) {
          const providerSnap = await db.collection("providers").doc(providerId).get();
          const pData = providerSnap.data();
          providerDaysCache.set(providerId, {
            nonWorkingDays: pData?.nonWorkingDays ?? [],
            vacations: pData?.vacations ?? [],
          });
        }
        
        const providerData = providerDaysCache.get(providerId)!;
        const nonWorkingDays = providerData.nonWorkingDays;
        const vacations = providerData.vacations;

        // To check holidays correctly, we must align the date to Buenos Aires time (UTC-3).
        const baDateCheck = new Date(finalDate.getTime() - (3 * 60 * 60 * 1000));
        const targetMMDD_BA = `${String(baDateCheck.getUTCMonth() + 1).padStart(2, "0")}-${String(baDateCheck.getUTCDate()).padStart(2, "0")}`;

        let isSkipped = false;
        let skipReason = "";

        if (nonWorkingDays.includes(targetMMDD_BA)) {
          isSkipped = true;
          skipReason = `holiday ${targetMMDD_BA}`;
        } else {
          // Check vacations
          for (const v of vacations) {
            const start = v.startDate?.toDate?.() ?? new Date(v.startDate);
            const end = v.endDate?.toDate?.() ?? new Date(v.endDate);
            
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
          console.log(`[dailyRecurringProcessor] Skipping recurring ${recurringDoc.id} because of ${skipReason}.`);
          skippedHolidaysCount++;
          
          // CRITICAL: We still need to update lastGeneratedDate to jump over it 
          // without creating the appointment.
          await recurringDoc.ref.update({
            lastGeneratedDate: admin.firestore.Timestamp.fromDate(targetDate),
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
            `[dailyRecurringProcessor] Appointment already exists for ${recurringDoc.id} on ${targetDateKey}`,
          );
          continue;
        }

        // ── Step 4: Create the appointment ──────────────────────────────
        const appointmentRef = patientRef.collection("appointments").doc();

        await appointmentRef.set({
          patientId,
          providerId,
          recurringAppointmentId: recurringDoc.id,
          concept,
          date: admin.firestore.Timestamp.fromDate(finalDate),
          dateKey: targetDateKey,
          totalAmount: defaultAmount,
          amountPaid: 0,
          status: "unpaid",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // ── Step 5: Update lastGeneratedDate ────────────────────────────
        await recurringDoc.ref.update({
          lastGeneratedDate: admin.firestore.Timestamp.fromDate(targetDate),
        });

        createdCount++;
        console.log(
          `[dailyRecurringProcessor] Created appointment for recurring ${recurringDoc.id} on ${targetDateKey}`,
        );
      } catch (error) {
        console.error(
          `[dailyRecurringProcessor] Error processing recurring ${recurringDoc.id}:`,
          error,
        );
      }
    }

    console.log(
      `[dailyRecurringProcessor] Finished. Created: ${createdCount}, Expired: ${expiredCount}, Skipped Holidays: ${skippedHolidaysCount}`,
    );
    return null;
  });
