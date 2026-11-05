import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { toDateKey } from "../utils/dateAndInterest";
import { enqueueMessage, calculateUrgentScheduledFor } from "../utils/messaging_utils";

const db = admin.firestore();

/**
 * Daily Cron Job — runs every day at 07:00 AM (Buenos Aires).
 *
 * Generates appointment reminder queue items for patients whose
 * appointments are scheduled in 1 or 2 days.  Only premium providers
 * with an active subscription receive reminders.
 *
 * Two passes per run:
 *  - **D+2 (normal):** catches appointments that already exist 2 days ahead.
 *  - **D+1 (catch-up):** catches appointments created after the previous
 *    day's 07:00 run that fell through the gap between the cron (D+2) and
 *    the onAppointmentCreated fast-path (<48 h threshold).
 *
 * Idempotent: the deterministic key `appt_{id}_0` prevents duplicate
 * queue items across runs and across the D+2 / D+1 passes.
 *
 * Runs 1 hour after dailyRecurringProcessor (06:00) so that
 * recurring appointments for the target date already exist.
 */
export const appointmentReminderGenerator = functions
  .runWith({ maxInstances: 1 })
  .pubsub.schedule("0 7 * * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async (_context) => {
    functions.logger.info("[appointmentReminderGenerator] Started");

    const now = new Date();

    // ── Caches (shared across both passes) ───────────────────────────
    const providerCache = new Map<
      string,
      { isPremiumActive: boolean; providerName: string }
    >();
    const patientNameCache = new Map<string, string>();

    // Counters (aggregated across both passes)
    let queuedCount = 0;
    let skippedNonPremium = 0;
    let skippedDuplicate = 0;
    let totalEligible = 0;

    // ── Process D+2 (normal) and D+1 (catch-up) ─────────────────────
    const offsets = [2, 1];

    for (const offset of offsets) {
      // ── 1. Calculate target date ───────────────────────────────────
      const targetDate = new Date(now);
      targetDate.setHours(0, 0, 0, 0);
      targetDate.setDate(targetDate.getDate() + offset);
      const targetDateKey = toDateKey(targetDate);

      functions.logger.info("[appointmentReminderGenerator] Processing offset", {
        offset,
        targetDateKey,
      });

      // ── 2. Query all appointments for the target date ──────────────
      const appointmentsSnapshot = await db
        .collectionGroup("appointments")
        .where("dateKey", "==", targetDateKey)
        .get();

      if (appointmentsSnapshot.empty) {
        functions.logger.info(
          "[appointmentReminderGenerator] No appointments found",
          { offset, targetDateKey }
        );
        continue;
      }

      // ── 3. Filter to scheduled / unpaid / free-liquidated ─────────
      // "liquidated" with totalAmount === 0 are free visits that still need reminders.
      const eligibleDocs = appointmentsSnapshot.docs.filter((doc) => {
        const data = doc.data();
        const status = data.status as string | undefined;
        if (status === "scheduled" || status === "unpaid") return true;
        if (status === "liquidated" && !(data.totalAmount > 0)) return true;
        return false;
      });

      if (eligibleDocs.length === 0) {
        functions.logger.info(
          "[appointmentReminderGenerator] No scheduled/unpaid appointments",
          { offset, targetDateKey }
        );
        continue;
      }

      totalEligible += eligibleDocs.length;

      functions.logger.info("[appointmentReminderGenerator] Eligible appointments", {
        offset,
        total: appointmentsSnapshot.size,
        eligible: eligibleDocs.length,
      });

      // ── 4. Process each appointment sequentially ───────────────────
      for (const appDoc of eligibleDocs) {
        try {
          const appData = appDoc.data();
          const providerId = appData.providerId as string | undefined;

          if (!providerId) continue;

          // ── 4a-c. Check provider eligibility (cached) ──────────────
          if (!providerCache.has(providerId)) {
            const providerSnap = await db
              .collection("providers")
              .doc(providerId)
              .get();

            if (!providerSnap.exists) {
              providerCache.set(providerId, { isPremiumActive: false, providerName: "" });
            } else {
              const pData = providerSnap.data()!;
              const isActive = pData.subscriptionStatus === "active";
              const isPremium = pData.plan === "premium";
              const name = pData.name as string | undefined;
              const profession = pData.profession as string | undefined | null;
              const providerName = profession ? `${profession} ${name ?? ""}` : (name ?? "");
              providerCache.set(providerId, {
                isPremiumActive: isActive && isPremium,
                providerName,
              });
            }
          }

          const provider = providerCache.get(providerId)!;
          if (!provider.isPremiumActive) {
            skippedNonPremium++;
            continue;
          }

          const providerName = provider.providerName;

          // ── 4d. Get patientId from the document path ───────────────
          // Path: providers/{pId}/patients/{patientId}/appointments/{appId}
          const patientRef = appDoc.ref.parent.parent;
          if (!patientRef) continue;
          const patientId = patientRef.id;

          // ── 4e. Get patient name (cached) ──────────────────────────
          if (!patientNameCache.has(patientRef.path)) {
            const patientSnap = await patientRef.get();
            const patientName = patientSnap.exists
              ? (patientSnap.data()?.name as string) ?? ""
              : "";
            patientNameCache.set(patientRef.path, patientName);
          }
          const patientName = patientNameCache.get(patientRef.path)!;

          // ── 4f. Determine urgency ──────────────────────────────────
          const appointmentDate = appData.date as admin.firestore.Timestamp | undefined;
          const appointmentCreatedAt = appData.createdAt as admin.firestore.Timestamp | undefined;

          if (!appointmentDate) continue;

          let isUrgent = false;
          let priority = 20;

          if (appointmentCreatedAt) {
            const diffMs =
              appointmentDate.toMillis() - appointmentCreatedAt.toMillis();
            const fortyEightHoursMs = 48 * 60 * 60 * 1000;
            if (diffMs < fortyEightHoursMs) {
              isUrgent = true;
              priority = 10;
            }
          }

          // ── 4g. Calculate scheduledFor ─────────────────────────────
          const appointmentDateObj = appointmentDate.toDate();
          let scheduledFor: Date;
          if (isUrgent) {
            scheduledFor = calculateUrgentScheduledFor(appointmentDateObj);
          } else {
            // Normal: 48h before, or now if already past that
            scheduledFor = new Date(
              appointmentDateObj.getTime() - 48 * 60 * 60 * 1000
            );
            if (scheduledFor < now) {
              scheduledFor = now;
            }
          }

          // ── 4h. Format date/time in Buenos Aires timezone ──────────
          const dateStr = appointmentDateObj.toLocaleDateString("es-AR", {
            timeZone: "America/Argentina/Buenos_Aires",
            day: "2-digit",
            month: "2-digit",
            year: "numeric",
          });
          const timeStr = appointmentDateObj.toLocaleTimeString("es-AR", {
            timeZone: "America/Argentina/Buenos_Aires",
            hour: "2-digit",
            minute: "2-digit",
            hour12: false,
          });

          // ── 4i. Read concept field ─────────────────────────────────
          const concept = (appData.concept as string | undefined) || "Consulta";

          // ── 4j. Enqueue the reminder (idempotent via deterministic ID)
          const result = await enqueueMessage({
            providerId,
            patientId,
            patientName,
            messageType: "appointment_reminder",
            variables: {
              nombre_paciente: patientName,
              fecha_turno: dateStr,
              hora_turno: timeStr,
              nombre_profesional: providerName,
              concepto_turno: concept,
            },
            priority,
            isUrgent,
            scheduledFor,
            expiresAt: appointmentDateObj,
            escalationLevel: 0,
            sourceAppointmentId: appDoc.id,
            idempotencyKey: `appt_${appDoc.id}_0`,
          });

          if (result.wasSkipped) {
            skippedDuplicate++;
          } else {
            queuedCount++;
          }
        } catch (error) {
          functions.logger.error(
            "[appointmentReminderGenerator] Error processing appointment",
            { appointmentId: appDoc.id, error }
          );
        }
      }
    }

    // ── 5. Log summary ───────────────────────────────────────────────
    functions.logger.info("[appointmentReminderGenerator] Finished", {
      totalEligible,
      skippedNonPremium,
      skippedDuplicate,
      queued: queuedCount,
    });

    return null;
  });
