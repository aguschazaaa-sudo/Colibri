import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  getMessagingConfig,
  getOrResetCounter,
  incrementCounter,
  getBuenosAiresHour,
} from "../utils/messaging_utils";

const db = admin.firestore();

export const messageOrchestrator = functions
  .runWith({ maxInstances: 1, timeoutSeconds: 540 })
  .pubsub.schedule("*/10 * * * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async () => {
    const config = await getMessagingConfig();

    if (!config.enabled) {
      functions.logger.info("messageOrchestrator disabled via config");
      return null;
    }

    // ── Time window check ─────────────────────────────────────────────────
    const currentHour = getBuenosAiresHour();

    if (currentHour < config.sendWindowStart || currentHour >= config.sendWindowEnd) {
      functions.logger.info("outside send window", { currentHour });
      return null;
    }

    // ── Counter reset (observability — no longer gates dispatch) ─────────
    await getOrResetCounter();

    // ── Urgency elevation pass ─────────────────────────────────────────────────
    // Promote queued messages to urgent when the appointment is within 24h.
    // Runs before the circuit breaker check — elevation costs no API calls.
    const nowForElevation = admin.firestore.Timestamp.now();

    const elevationSnap = await db
      .collection("message_queue")
      .where("status", "==", "queued")
      .where("scheduledFor", "<=", nowForElevation)
      .where("isUrgent", "==", false)
      .get();

    if (!elevationSnap.empty) {
      const elevationBatch = db.batch();
      for (const doc of elevationSnap.docs) {
        elevationBatch.update(doc.ref, { isUrgent: true, priority: 10 });
      }
      await elevationBatch.commit();
      functions.logger.info("urgency elevation completed", {
        elevatedCount: elevationSnap.size,
      });
    }

    // ── Circuit breaker: skip dispatch if pausedUntil is in the future ────
    if (config.pausedUntil && config.pausedUntil.toMillis() > Date.now()) {
      functions.logger.info("dispatch paused due to tier exhaustion", {
        pausedUntil: config.pausedUntil.toMillis(),
      });
      return null;
    }

    // ── Pacing: defensive 80 MPS limit ───────────────────────────────────
    const rate = config.maxDispatchRatePerSecond ?? 40;
    const minDelayMs = (rate > 0 && isFinite(rate)) ? Math.ceil(1000 / rate) : 0;

    // ── Main processing ───────────────────────────────────────────────────
    const now = admin.firestore.Timestamp.now();

    const snapshot = await db
      .collection("message_queue")
      .where("status", "==", "queued")
      .where("scheduledFor", "<=", now)
      .orderBy("scheduledFor", "asc")
      .orderBy("isUrgent", "desc")
      .orderBy("priority", "asc")
      .orderBy("createdAt", "asc")
      .limit(500)
      .get();

    functions.logger.info("messageOrchestrator dispatch query result", {
      count: snapshot.size,
    });

    if (snapshot.empty) {
      functions.logger.info("no messages to process");
      return null;
    }

    let processedCount = 0;
    let normalSent = 0;
    let urgentSent = 0;

    for (const msgDoc of snapshot.docs) {
      const msg = msgDoc.data();

      // Expiry check
      if (msg.expiresAt && msg.expiresAt.toMillis() < now.toMillis()) {
        await msgDoc.ref.update({ status: "expired" });
        processedCount++;
        continue;
      }

      // Create communication document
      const commRef = db
        .collection("providers")
        .doc(msg.providerId)
        .collection("communications")
        .doc();

      const commData = {
        providerId: msg.providerId,
        patientId: msg.patientId,
        patientName: msg.patientName,
        type: "whatsapp_reminder",
        messageType: msg.messageType,
        status: "pending",
        totalDebtAtThatTime: msg.variables?.monto_total ?? 0,
        variables: msg.variables ?? {},
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        queueItemId: msgDoc.id,
      };

      await commRef.set(commData);

      // Mirror to patient sub-collection
      await db
        .collection("providers")
        .doc(msg.providerId)
        .collection("patients")
        .doc(msg.patientId)
        .collection("communications")
        .doc(commRef.id)
        .set(commData);

      // Update queue item
      await msgDoc.ref.update({
        status: "processing",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await incrementCounter(msg.isUrgent);

      // Pacing: enforce max dispatch rate per second
      if (minDelayMs > 0) {
        await new Promise((r) => setTimeout(r, minDelayMs));
      }

      if (msg.isUrgent) {
        urgentSent++;
      } else {
        normalSent++;
      }
      processedCount++;
    }

    functions.logger.info("messageOrchestrator completed", {
      processedCount,
      normalSent,
      urgentSent,
    });

    return null;
  });
