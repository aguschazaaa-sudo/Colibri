import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { normalizeArgentinePhone } from "../utils/messaging_utils";

// eslint-disable-next-line @typescript-eslint/no-require-imports
const createTwilioClient = require("twilio") as (
  accountSid: string,
  authToken: string
) => ReturnType<typeof import("twilio")>;

const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioWhatsappFrom = defineSecret("TWILIO_WHATSAPP_FROM");

const db = admin.firestore();

/** Any |stored - computed| above this (ARS) is auto-repaired. */
const REPAIR_THRESHOLD = 1;
/** Big-drift alert: the difference must exceed BOTH thresholds. */
const ALERT_ABSOLUTE_THRESHOLD = 150_000;
const ALERT_PERCENT_THRESHOLD = 5;

/**
 * Scheduled Cloud Function: weeklyDashboardReconciler
 *
 * NOTE: despite the (kept-for-deploy-compatibility) name, this now runs
 * DAILY at 06:00 ART. Renaming it would create a new deployed function and
 * leave the old weekly one behind.
 *
 * For every provider with an active or past_due subscription it recomputes
 * `totalToCollect` by summing `patient.totalDebt` across all patient
 * documents and compares it to the stored value in
 * `providers/{providerId}/metrics/dashboard`.
 *
 * Auto-heal: when |stored - computed| > ARS 1, it REPAIRS `totalToCollect` to
 * the computed value (stamping `lastReconciliationAt` and
 * `lastReconciliationDiff = stored - computed`, same as
 * migrations-recomputeProviderDashboard with force=true). The read of all
 * patients + dashboard and the repair run in ONE transaction, so a ledger
 * trigger committing concurrently (which updates patient + dashboard
 * atomically) can never be lost or double-counted by the repair.
 *
 * Alert: a WhatsApp alert to `metadata/messaging.adminAlertPhone` is sent only
 * for big drifts, i.e. the difference exceeds BOTH:
 *   - ARS 150,000 absolute
 *   - 5 % of the computed value
 * A big drift means a ledger bug is still producing drift and must be
 * investigated, even though the value was already repaired.
 *
 * Logs never include amounts (PII rule) — only percentDrift and counts.
 */
export const weeklyDashboardReconciler = functions
  .runWith({
    timeoutSeconds: 540,
    memory: "512MB",
    secrets: ["TWILIO_ACCOUNT_SID", "TWILIO_AUTH_TOKEN", "TWILIO_WHATSAPP_FROM"],
  })
  .pubsub.schedule("0 6 * * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async (_context) => {
    functions.logger.info("[weeklyDashboardReconciler] Starting reconciliation run");

    // ── 1. Read admin alert config from metadata ─────────────────────────────
    const metaSnap = await db.collection("metadata").doc("messaging").get();
    const metaData = metaSnap.data();
    const adminAlertPhone = metaData?.adminAlertPhone as string | undefined;
    const templateSid = metaData?.templates?.payment_reminder?.contentSid as string | undefined;

    // ── 2. Fetch all active / past_due providers ─────────────────────────────
    const providersSnap = await db
      .collection("providers")
      .where("subscriptionStatus", "in", ["active", "past_due"])
      .get();

    functions.logger.info(
      `[weeklyDashboardReconciler] Providers to check: ${providersSnap.size}`,
    );

    let driftCount = 0; // big drifts (alert-worthy)
    let repairedCount = 0;
    let healthyCount = 0;
    let failedCount = 0;
    const driftingProviders: Array<{ name: string; percentDrift: string }> = [];

    // ── 3. Check (and repair) each provider ──────────────────────────────────
    for (const providerDoc of providersSnap.docs) {
      const providerId = providerDoc.id;
      const providerName: string = providerDoc.data().name ?? providerId;

      const providerRef = db.collection("providers").doc(providerId);
      const patientsRef = providerRef.collection("patients");
      const dashRef = providerRef.collection("metrics").doc("dashboard");

      try {
        // Values are returned from the closure (fresh per attempt), never
        // accumulated outside it — the closure may be re-run on contention.
        const result = await db.runTransaction(async (transaction) => {
          const [patientsSnap, dashSnap] = await Promise.all([
            transaction.get(patientsRef),
            transaction.get(dashRef),
          ]);

          let computed = 0;
          for (const patDoc of patientsSnap.docs) {
            const debt = patDoc.data().totalDebt;
            computed += typeof debt === "number" && isFinite(debt) ? debt : 0;
          }

          const storedRaw = dashSnap.data()?.totalToCollect;
          const stored: number =
            typeof storedRaw === "number" && isFinite(storedRaw) ? storedRaw : 0;

          const delta = stored - computed;
          const needsRepair = Math.abs(delta) > REPAIR_THRESHOLD;

          if (needsRepair) {
            transaction.set(
              dashRef,
              {
                totalToCollect: computed,
                lastReconciliationAt: admin.firestore.FieldValue.serverTimestamp(),
                lastReconciliationDiff: delta,
              },
              { merge: true },
            );
          }

          return {
            computed,
            diff: Math.abs(delta),
            needsRepair,
            patientCount: patientsSnap.size,
          };
        });

        const percentDrift =
          result.computed !== 0 ? (result.diff / result.computed) * 100 : 0;
        const isBigDrift =
          result.diff > ALERT_ABSOLUTE_THRESHOLD &&
          percentDrift > ALERT_PERCENT_THRESHOLD;

        if (isBigDrift) {
          driftCount++;
          driftingProviders.push({ name: providerName, percentDrift: percentDrift.toFixed(0) });
          functions.logger.warn(
            "[weeklyDashboardReconciler] DASHBOARD_DRIFT_DETECTED",
            {
              providerId,
              percentDrift: percentDrift.toFixed(2),
              patientCount: result.patientCount,
              repaired: result.needsRepair,
            },
          );
        }

        if (result.needsRepair) {
          repairedCount++;
          functions.logger.info(
            "[weeklyDashboardReconciler] Repaired totalToCollect",
            { providerId, percentDrift: percentDrift.toFixed(2) },
          );
        } else {
          healthyCount++;
          functions.logger.info(
            "[weeklyDashboardReconciler] Provider metrics healthy",
            { providerId },
          );
        }
      } catch (providerError) {
        failedCount++;
        functions.logger.error(
          "[weeklyDashboardReconciler] Failed to reconcile provider",
          { providerId, error: String(providerError) },
        );
      }
    }

    functions.logger.info(
      "[weeklyDashboardReconciler] Reconciliation complete",
      {
        total: providersSnap.size,
        driftCount,
        repairedCount,
        healthyCount,
        failedCount,
      },
    );

    // ── 4. WhatsApp alert if drift found and admin phone is configured ────────
    if (driftCount > 0 && adminAlertPhone && templateSid) {
      try {
        const normalizedPhone = normalizeArgentinePhone(adminAlertPhone);
        const client = createTwilioClient(
          twilioAccountSid.value(),
          twilioAuthToken.value(),
        );

        // Uses the payment_reminder template with repurposed variables:
        //   1 = provider name(s) with drift  →  nombre_paciente field
        //   2 = "Cobrador"                   →  profesional field
        //   3 = drift %                      →  monto_total field
        //   4 = "el dashboard"               →  detalle_origen field
        //   5 = ""                           →  fechas field (unused)
        const providerList = driftingProviders
          .map((p) => `${p.name} (${p.percentDrift}%)`)
          .join(", ");

        await client.messages.create({
          from: twilioWhatsappFrom.value(),
          to: normalizedPhone,
          contentSid: templateSid,
          contentVariables: JSON.stringify({
            "1": providerList,
            "2": "Cobrador",
            "3": `${driftCount} proveedor${driftCount > 1 ? "es" : ""}`,
            "4": "el dashboard",
            "5": "",
          }),
        });

        functions.logger.info(
          "[weeklyDashboardReconciler] Admin WhatsApp alert sent",
          { driftCount },
        );
      } catch (alertError) {
        functions.logger.error(
          "[weeklyDashboardReconciler] Failed to send admin WhatsApp alert",
          { error: String(alertError) },
        );
      }
    }
  });
