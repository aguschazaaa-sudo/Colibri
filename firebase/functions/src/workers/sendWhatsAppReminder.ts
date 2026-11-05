import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
// twilio uses `export =` which requires esModuleInterop for default import.
// We use require() and cast to the callable type to avoid tsconfig changes.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const createTwilioClient = require("twilio") as (
  accountSid: string,
  authToken: string
) => ReturnType<typeof import("twilio")>;
import {
  resolveTemplateContentSid,
  buildTwilioContentVariables,
  TemplateNotConfiguredError,
  normalizeArgentinePhone,
  MessageType,
  getMessagingConfig,
} from "../utils/messaging_utils";

const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioWhatsappFrom = defineSecret("TWILIO_WHATSAPP_FROM");

const db = admin.firestore();

/**
 * Worker triggered when a communication document is created in
 * `providers/{providerId}/communications/{commId}`.
 *
 * Sends a WhatsApp reminder via Twilio Content API using the template
 * configured for the provider or the global default.
 *
 * Abort reasons (no Twilio call, no retry):
 *  - `subscription_inactive`: provider is not `active`
 *  - `no_phone`: patient has no phone number
 *  - `template_not_configured`: no Content SID found for the messageType
 *
 * Retry policy (transient Twilio errors — 429 or 5xx / ECONNRESET / ETIMEDOUT):
 *  - Up to 3 attempts with quadratic back-off (1s, 4s)
 *
 * PII rules: phone numbers, patient names, and monetary amounts MUST NOT appear in any log.
 */
export const sendWhatsAppReminder = functions
  .runWith({
    maxInstances: 10,
    secrets: [twilioAccountSid, twilioAuthToken, twilioWhatsappFrom],
  })
  .firestore
  .document("providers/{providerId}/communications/{commId}")
  .onCreate(async (snap, context) => {
    const commId = context.params.commId;
    const providerId = context.params.providerId;
    const data = snap.data();

    if (data.status !== "pending") return null;
    if (data.type !== "whatsapp_reminder") return null;

    const { patientId, queueItemId } = data;
    const msg = data;

    try {
      // ── Guard: provider must be active ────────────────────────────
      const providerSnap = await db.collection("providers").doc(providerId).get();
      const providerData = providerSnap.data();
      if (!providerData || providerData.subscriptionStatus !== "active") {
        await snap.ref.update({
          status: "aborted",
          reason: "subscription_inactive",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await mirrorPatientUpdate(providerId, patientId, commId, {
          status: "aborted",
          reason: "subscription_inactive",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await updateQueueItemStatus(queueItemId, "failed", "subscription_inactive");
        return null;
      }

      // ── Read patient phone ────────────────────────────────────────
      const patientSnap = await db
        .collection("providers").doc(providerId)
        .collection("patients").doc(patientId)
        .get();
      const patientData = patientSnap.data();
      const phone = patientData?.phoneNumber as string | undefined;
      if (!phone || phone.trim() === "") {
        functions.logger.warn("[sendWhatsAppReminder] patient has no phone", { commId });
        await snap.ref.update({
          status: "aborted",
          reason: "no_phone",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await mirrorPatientUpdate(providerId, patientId, commId, {
          status: "aborted",
          reason: "no_phone",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await updateQueueItemStatus(queueItemId, "failed", "no_phone");
        return null;
      }

      // ── Resolve template SID ──────────────────────────────────────
      const messageType = data.messageType as MessageType;
      let contentSid: string;
      try {
        contentSid = await resolveTemplateContentSid(providerId, messageType);
      } catch (e) {
        if (e instanceof TemplateNotConfiguredError) {
          functions.logger.warn("[sendWhatsAppReminder] template not configured", {
            providerId,
            messageType,
            commId,
          });
          await snap.ref.update({
            status: "aborted",
            reason: "template_not_configured",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          await mirrorPatientUpdate(providerId, patientId, commId, {
            status: "aborted",
            reason: "template_not_configured",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          await updateQueueItemStatus(queueItemId, "failed", "template_not_configured");
          return null;
        }
        throw e;
      }

      // ── Build content variables ───────────────────────────────────
      const contentVariables = buildTwilioContentVariables(messageType, msg.variables ?? {});

      // ── Send via Twilio with retry ────────────────────────────────
      // Normalize phone to E.164 before sending
      const normalizedPhone = normalizeArgentinePhone(phone);

      const messageSid = await sendViaTwilio(
        twilioWhatsappFrom.value(),
        `whatsapp:${normalizedPhone}`,
        contentSid,
        contentVariables
      );

      // ── Success ───────────────────────────────────────────────────
      await snap.ref.update({
        status: "sent",
        messageId: messageSid,
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await mirrorPatientUpdate(providerId, patientId, commId, {
        status: "sent",
        messageId: messageSid,
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await updateQueueItemStatus(queueItemId, "sent");

      functions.logger.info("[sendWhatsAppReminder] sent successfully", { commId });
      return null;
    } catch (error) {
      // ── Meta tier exhaustion: rollback and pause dispatch ────────────────
      if (isMetaTierExhaustion(error)) {
        const messagingConfig = await getMessagingConfig();
        await rollbackTierExhausted({
          snap,
          commId,
          queueItemId,
          providerId,
          patientId,
          tierExhaustedPauseMs: messagingConfig.tierExhaustedPauseMs ?? 30 * 60 * 1000,
        });
        return null;
      }

      functions.logger.error("[sendWhatsAppReminder] unhandled error", { commId });
      // Sanitize error message before persisting to Firestore to avoid leaking PII
      // (Twilio errors may include phone numbers in the message).
      const safeError = sanitizeError(error);
      await snap.ref.update({
        status: "failed",
        lastError: safeError,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await mirrorPatientUpdate(providerId, patientId, commId, {
        status: "failed",
        lastError: safeError,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await updateQueueItemStatus(queueItemId, "failed", safeError);
      return null;
    }
  });

/**
 * Returns true when the error is a Meta tier exhaustion (daily message limit reached).
 * Twilio surfaces these as errors with numeric code 63038 or 63032.
 */
function isMetaTierExhaustion(err: unknown): boolean {
  if (!err || typeof err !== "object") return false;
  const e = err as { code?: unknown };
  return e.code === 63038 || e.code === 63032;
}

/**
 * Rolls back a communication document when Meta tier exhaustion is detected.
 *
 * Actions:
 *  1. Deletes the comm doc in `providers/{providerId}/communications/{commId}`.
 *  2. Deletes the patient mirror in `providers/{providerId}/patients/{patientId}/communications/{commId}`.
 *  3. Resets the queue item to `queued` and removes `processedAt` (NO attempts increment).
 *  4. Writes `pausedUntil` to `metadata/messaging` so the orchestrator skips next cycles.
 *
 * All steps are individually wrapped in try/catch so a missing mirror or queue item
 * does not prevent the pause from being written.
 */
async function rollbackTierExhausted(params: {
  snap: FirebaseFirestore.DocumentSnapshot;
  commId: string;
  queueItemId: string | undefined;
  providerId: string;
  patientId: string;
  tierExhaustedPauseMs: number;
}): Promise<void> {
  const { snap, commId, queueItemId, providerId, patientId, tierExhaustedPauseMs } = params;

  // 1. Delete comm doc
  await snap.ref.delete();

  // 2. Delete patient mirror (best-effort)
  try {
    await db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId)
      .collection("communications")
      .doc(commId)
      .delete();
  } catch (err) {
    functions.logger.warn("[sendWhatsAppReminder] could not delete patient comm mirror", { commId });
  }

  // 3. Reset queue item back to queued (no attempts increment)
  if (queueItemId) {
    try {
      await db.collection("message_queue").doc(queueItemId).update({
        status: "queued",
        processedAt: admin.firestore.FieldValue.delete(),
      });
    } catch (err) {
      functions.logger.warn("[sendWhatsAppReminder] could not reset queue item", { queueItemId });
    }
  }

  // 4. Write pausedUntil to metadata/messaging (merge so other fields are preserved)
  const pausedUntil = admin.firestore.Timestamp.fromMillis(Date.now() + tierExhaustedPauseMs);
  await db.collection("metadata").doc("messaging").set({ pausedUntil }, { merge: true });

  functions.logger.info("[sendWhatsAppReminder] tier exhausted, rolled back", {
    commId,
    queueItemId,
  });
}

/**
 * Sends a WhatsApp message via Twilio with up to 3 attempts.
 *
 * Retriable errors: HTTP 429, HTTP 5xx, and network errors (ECONNRESET, ETIMEDOUT, ENOTFOUND).
 * Back-off: attempt^2 seconds between retries (1s after attempt 1, 4s after attempt 2).
 */
async function sendViaTwilio(
  from: string,
  to: string,
  contentSid: string,
  contentVariables: Record<string, string>
): Promise<string> {
  const client = createTwilioClient(twilioAccountSid.value(), twilioAuthToken.value());

  const MAX_ATTEMPTS = 3;
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      const message = await client.messages.create({
        from,
        to,
        contentSid,
        contentVariables: JSON.stringify(contentVariables),
      });
      return message.sid;
    } catch (err: unknown) {
      lastError = err as Error;
      const shouldRetry = isRetriableError(err);
      if (!shouldRetry || attempt === MAX_ATTEMPTS) break;
      await new Promise((resolve) => setTimeout(resolve, attempt * attempt * 1000));
    }
  }

  throw lastError!;
}

function isRetriableError(err: unknown): boolean {
  if (!err || typeof err !== "object") return false;
  const e = err as { status?: number; code?: string; message?: string };
  if (typeof e.status === "number") {
    return e.status === 429 || e.status >= 500;
  }
  if (e.code === "ECONNRESET" || e.code === "ETIMEDOUT" || e.code === "ENOTFOUND") {
    return true;
  }
  return false;
}

async function mirrorPatientUpdate(
  providerId: string,
  patientId: string,
  commId: string,
  data: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>
) {
  if (!providerId || !patientId || !commId) return;
  await db
    .collection("providers").doc(providerId)
    .collection("patients").doc(patientId)
    .collection("communications").doc(commId)
    .set(data, { merge: true });
}

/**
 * Returns a safe error string for persistence in Firestore.
 * Strips phone numbers and other potential PII from Twilio error messages.
 */
function sanitizeError(err: unknown): string {
  const raw = err instanceof Error ? err.message : String(err);
  // Strip E.164 phone numbers (e.g. +5491155551234)
  return raw.replace(/\+?\d[\d\s\-().]{7,}\d/g, "[phone]");
}

async function updateQueueItemStatus(
  queueItemId: string | undefined,
  status: "sent" | "failed",
  errorMsg?: string
) {
  if (!queueItemId) return;
  try {
    const queueRef = db.collection("message_queue").doc(queueItemId);
    const updates: Record<string, unknown> = {
      status,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (status === "failed") {
      updates.lastError = errorMsg;
      updates.attempts = admin.firestore.FieldValue.increment(1);
    }
    await queueRef.update(updates);
  } catch (err) {
    functions.logger.warn("[sendWhatsAppReminder] failed to update queue item", { queueItemId });
  }
}
