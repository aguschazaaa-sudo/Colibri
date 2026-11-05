import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { z } from "zod";
import { toDateKey } from "../utils/dateAndInterest";
import { processRecurringForTargetDate } from "../cron/dailyRecurringProcessor";
export { onErrorReportCreated } from "./onErrorReportCreated";
export { getTwilioSenderInfo } from "./getTwilioSenderInfo";

const db = admin.firestore();
const BATCH_LIMIT = 500;

// ─── recomputeProviderDashboard ──────────────────────────────────────────────

const RecomputeDashboardBodySchema = z.object({
  providerId: z.string().min(1),
  force: z.boolean().optional().default(false),
});

/**
 * Manual HTTP trigger to recompute `totalToCollect` for a single provider
 * by summing `totalDebt` across all patient documents and comparing it to
 * the stored value in `providers/{providerId}/metrics/dashboard`.
 *
 * POST body (required):
 *   { "providerId": "<id>", "force": true }
 *   — If `force` is omitted or false, only reports the drift without repairing.
 *   — If `force` is true, sets `totalToCollect` to the computed value and stamps
 *     `lastReconciliationAt`.
 *
 * Security: requires header `X-Admin-Secret` matching env var `ADMIN_SECRET`.
 *
 * Example (curl):
 *   curl -X POST \
 *     -H "Content-Type: application/json" \
 *     -H "X-Admin-Secret: <secret>" \
 *     -d '{"providerId":"abc123","force":true}' \
 *     https://<region>-<project>.cloudfunctions.net/migrations-recomputeProviderDashboard
 */
export const recomputeProviderDashboard = functions
  .runWith({ maxInstances: 1, timeoutSeconds: 300, secrets: ["ADMIN_SECRET"] })
  .https.onRequest(async (req, res) => {
    // ── Only POST ────────────────────────────────────────────────────────────
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed. Use POST." });
      return;
    }

    // ── Auth: X-Admin-Secret header ──────────────────────────────────────────
    const adminSecret = process.env.ADMIN_SECRET;
    if (!adminSecret) {
      console.error(
        "[recomputeProviderDashboard] ADMIN_SECRET env var is not set.",
      );
      res.status(500).json({ error: "Internal server error." });
      return;
    }

    const providedSecret = req.headers["x-admin-secret"];
    const secretsMatch =
      typeof providedSecret === "string" &&
      providedSecret.length === adminSecret.length &&
      crypto.timingSafeEqual(
        Buffer.from(providedSecret),
        Buffer.from(adminSecret),
      );
    if (!secretsMatch) {
      res.status(403).json({ error: "Forbidden." });
      return;
    }

    // ── Validate body ────────────────────────────────────────────────────────
    const parseResult = RecomputeDashboardBodySchema.safeParse(req.body ?? {});
    if (!parseResult.success) {
      console.error(
        "[recomputeProviderDashboard] Invalid body:",
        parseResult.error.flatten(),
      );
      res.status(400).json({ error: "Invalid request body." });
      return;
    }

    const { providerId, force } = parseResult.data;

    // ── Sum totalDebt across all patients ────────────────────────────────────
    const patientsSnap = await db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .get();

    let computed = 0;
    for (const patDoc of patientsSnap.docs) {
      const debt = patDoc.data().totalDebt;
      computed += typeof debt === "number" && isFinite(debt) ? debt : 0;
    }

    // ── Read current stored value ────────────────────────────────────────────
    const dashRef = db
      .collection("providers")
      .doc(providerId)
      .collection("metrics")
      .doc("dashboard");

    const dashSnap = await dashRef.get();
    const stored: number =
      typeof dashSnap.data()?.totalToCollect === "number"
        ? (dashSnap.data()!.totalToCollect as number)
        : 0;

    const delta = stored - computed;
    const percentDrift = computed !== 0 ? (delta / computed) * 100 : 0;

    // ── Structured log (no amounts — amounts are PII per project rules) ────────
    functions.logger.info("[recomputeProviderDashboard] Drift report", {
      providerId,
      hasDrift: delta !== 0,
      percentDrift: percentDrift.toFixed(2),
      patientCount: patientsSnap.size,
      force,
    });

    // ── Optional repair ──────────────────────────────────────────────────────
    if (force) {
      await dashRef.set(
        {
          totalToCollect: computed,
          lastReconciliationAt: admin.firestore.FieldValue.serverTimestamp(),
          lastReconciliationDiff: delta,
        },
        { merge: true },
      );
      functions.logger.info(
        "[recomputeProviderDashboard] Repaired totalToCollect",
        { providerId },
      );
    }

    res.status(200).json({ computed, stored, delta, repaired: force });
  });

// ─── Input schema ─────────────────────────────────────────────────────────────

const BackfillBodySchema = z.object({
  offsetDays: z
    .array(z.number().int().min(0).max(7))
    .optional()
    .default([1, 2]),
});

// ─── backfillRecurringAppointments ───────────────────────────────────────────

/**
 * Manual HTTP trigger to backfill recurring appointments for specific day offsets.
 *
 * POST body (optional):
 *   { "offsetDays": [1, 2] }   — array of integer offsets from today (0-7).
 *   If omitted, defaults to [1, 2].
 *
 * Security: requires header `X-Admin-Secret` matching env var `ADMIN_SECRET`.
 *
 * Example (curl):
 *   curl -X POST \
 *     -H "Content-Type: application/json" \
 *     -H "X-Admin-Secret: <secret>" \
 *     -d '{"offsetDays":[1,2]}' \
 *     https://<region>-<project>.cloudfunctions.net/migrations-backfillRecurringAppointments
 */
export const backfillRecurringAppointments = functions
  .runWith({ maxInstances: 1, secrets: ["ADMIN_SECRET"] })
  .https.onRequest(async (req, res) => {
    // ── Only POST ────────────────────────────────────────────────────────────
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed. Use POST." });
      return;
    }

    // ── Auth: X-Admin-Secret header ──────────────────────────────────────────
    const adminSecret = process.env.ADMIN_SECRET;
    if (!adminSecret) {
      console.error(
        "[backfillRecurringAppointments] ADMIN_SECRET env var is not set.",
      );
      res.status(500).json({ error: "Internal server error." });
      return;
    }

    const providedSecret = req.headers["x-admin-secret"];
    const secretsMatch =
      typeof providedSecret === "string" &&
      providedSecret.length === adminSecret.length &&
      crypto.timingSafeEqual(
        Buffer.from(providedSecret),
        Buffer.from(adminSecret),
      );
    if (!secretsMatch) {
      res.status(403).json({ error: "Forbidden." });
      return;
    }

    // ── Validate body ────────────────────────────────────────────────────────
    const parseResult = BackfillBodySchema.safeParse(req.body ?? {});
    if (!parseResult.success) {
      console.error(
        "[backfillRecurringAppointments] Invalid body:",
        parseResult.error.flatten(),
      );
      res.status(400).json({ error: "Invalid request body." });
      return;
    }

    const { offsetDays } = parseResult.data;

    console.log(
      `[backfillRecurringAppointments] Manual backfill started for offsets: [${offsetDays.join(", ")}]`,
    );

    // ── Process each offset ──────────────────────────────────────────────────
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const results: Array<{
      dateKey: string;
      created: number;
      expired: number;
      skippedHolidays: number;
    }> = [];

    for (const offset of offsetDays) {
      const targetDate = new Date(today);
      targetDate.setDate(targetDate.getDate() + offset);
      const dateKey = toDateKey(targetDate);

      console.log(
        `[backfillRecurringAppointments] Processing offset +${offset} → ${dateKey}`,
      );

      const { createdCount, expiredCount, skippedHolidaysCount } =
        await processRecurringForTargetDate(targetDate, db);

      results.push({
        dateKey,
        created: createdCount,
        expired: expiredCount,
        skippedHolidays: skippedHolidaysCount,
      });
    }

    console.log(
      `[backfillRecurringAppointments] Completed. Results: ${JSON.stringify(results)}`,
    );

    res.status(200).json({ results });
  });

// ─── backfillDateKey ────────────────────────────────────────────────────────

/**
 * Manual HTTP trigger to backfill the `dateKey` field on existing appointments
 * that are missing it.
 *
 * Queries ALL appointments via collectionGroup, filters those without `dateKey`,
 * computes it from the `date` Timestamp using `toDateKey()`, and batch-updates.
 *
 * Security: requires header `X-Admin-Secret` matching env var `ADMIN_SECRET`.
 *
 * Example (curl):
 *   curl -X POST \
 *     -H "X-Admin-Secret: <secret>" \
 *     https://<region>-<project>.cloudfunctions.net/migrations-backfillDateKey
 */
export const backfillDateKey = functions
  .runWith({ maxInstances: 1, timeoutSeconds: 540, secrets: ["ADMIN_SECRET"] })
  .https.onRequest(async (req, res) => {
    // ── Only POST ────────────────────────────────────────────────────────────
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed. Use POST." });
      return;
    }

    // ── Auth: X-Admin-Secret header ──────────────────────────────────────────
    const adminSecret = process.env.ADMIN_SECRET;
    if (!adminSecret) {
      console.error("[backfillDateKey] ADMIN_SECRET env var is not set.");
      res.status(500).json({ error: "Internal server error." });
      return;
    }

    const providedSecret = req.headers["x-admin-secret"];
    const secretsMatch =
      typeof providedSecret === "string" &&
      providedSecret.length === adminSecret.length &&
      crypto.timingSafeEqual(
        Buffer.from(providedSecret),
        Buffer.from(adminSecret),
      );
    if (!secretsMatch) {
      res.status(403).json({ error: "Forbidden." });
      return;
    }

    console.log("[backfillDateKey] Starting backfill of dateKey field...");

    // ── Query all appointments ───────────────────────────────────────────────
    const allAppointments = await db
      .collectionGroup("appointments")
      .get();

    let updatedCount = 0;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of allAppointments.docs) {
      const data = doc.data();

      // Skip if dateKey already exists
      if (data.dateKey) {
        continue;
      }

      // Skip if no date field
      if (!data.date || !data.date.toDate) {
        console.warn(
          `[backfillDateKey] Skipping doc ${doc.ref.path}: missing or invalid date field.`,
        );
        continue;
      }

      const dateKey = toDateKey(data.date.toDate());
      batch.update(doc.ref, { dateKey });
      batchCount++;
      updatedCount++;

      // Commit batch when reaching the limit
      if (batchCount >= BATCH_LIMIT) {
        await batch.commit();
        console.log(
          `[backfillDateKey] Committed batch of ${batchCount} updates.`,
        );
        batch = db.batch();
        batchCount = 0;
      }
    }

    // Commit remaining
    if (batchCount > 0) {
      await batch.commit();
      console.log(
        `[backfillDateKey] Committed final batch of ${batchCount} updates.`,
      );
    }

    console.log(
      `[backfillDateKey] Completed. Total documents updated: ${updatedCount} out of ${allAppointments.size} total.`,
    );

    res.status(200).json({
      totalAppointments: allAppointments.size,
      updatedCount,
    });
  });
