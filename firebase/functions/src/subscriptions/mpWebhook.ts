import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";
import { MercadoPagoConfig, PreApproval, Invoice } from "mercadopago";

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");
const mpWebhookSecret = defineSecret("MP_WEBHOOK_SECRET");

const db = admin.firestore();
const GRACE_PERIOD_MS = 3 * 24 * 60 * 60 * 1000; // 3 days

/**
 * Validates the x-signature header sent by MercadoPago
 * to ensure the request is authentic.
 */
function validateSignature(req: functions.https.Request, secret: string): boolean {
  try {
    const xSignature = req.headers["x-signature"] as string;
    const xRequestId = req.headers["x-request-id"] as string | undefined;
    const dataId = req.query["data.id"] as string | undefined;

    if (!xSignature || !dataId) {
      functions.logger.warn("Webhook missing required fields", {
        hasXSignature: !!xSignature,
        hasDataId: !!dataId,
        hasXRequestId: !!xRequestId,
      });
      return false;
    }

    const parts = xSignature.split(",");
    let ts = "";
    let v1 = "";
    for (const part of parts) {
      const [key, value] = part.split("=");
      if (key.trim() === "ts") ts = value.trim();
      if (key.trim() === "v1") v1 = value.trim();
    }

    if (!ts || !v1) return false;

    // x-request-id es opcional según docs de MP:
    // Con header:  id:{data.id};request-id:{x-request-id};ts:{ts};
    // Sin header:  id:{data.id};ts:{ts};
    const signedTemplate = xRequestId
      ? `id:${dataId};request-id:${xRequestId};ts:${ts};`
      : `id:${dataId};ts:${ts};`;

    const computedHash = crypto
      .createHmac("sha256", secret)
      .update(signedTemplate)
      .digest("hex");

    if (computedHash.length !== v1.length) {
      functions.logger.warn("Webhook signature length mismatch", {
        hasXRequestId: !!xRequestId,
        templateFormat: xRequestId ? "with-request-id" : "without-request-id",
      });
      return false;
    }

    const isValid = crypto.timingSafeEqual(
      Buffer.from(computedHash),
      Buffer.from(v1)
    );

    if (!isValid) {
      functions.logger.warn("Webhook signature mismatch", {
        hasXRequestId: !!xRequestId,
        templateFormat: xRequestId ? "with-request-id" : "without-request-id",
      });
    }

    return isValid;
  } catch (e) {
    functions.logger.warn("Signature validation error", e);
    return false;
  }
}

/** Maps a MercadoPago preapproval status to our internal subscription status. */
function mapStatus(mpStatus: string | undefined): string {
  switch (mpStatus) {
    case "authorized": return "active";
    case "pending":    return "pending";
    case "paused":     return "pastDue";
    case "cancelled":  return "suspended";
    default:           return "pastDue";
  }
}

/**
 * Calculates the subscription expiry from MP's next_payment_date + grace period.
 * Falls back to now + 30 days + grace if MP doesn't provide the date.
 */
function calculateExpiresAt(nextPaymentDate: string | null | undefined): admin.firestore.Timestamp {
  const base = nextPaymentDate
    ? new Date(nextPaymentDate).getTime()
    : Date.now() + 30 * 24 * 60 * 60 * 1000;
  return admin.firestore.Timestamp.fromDate(new Date(base + GRACE_PERIOD_MS));
}

/** Idempotency: check if this event ID was already processed. */
async function isAlreadyProcessed(eventId: string): Promise<boolean> {
  const ref = db.collection("webhook_events").doc(eventId);
  const snap = await ref.get();
  return snap.exists;
}

/** Mark an event as successfully processed (call AFTER processing succeeds). */
async function markProcessed(eventId: string): Promise<void> {
  await db.collection("webhook_events").doc(eventId).set({
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export const mpWebhook = functions
  .runWith({ secrets: [mpAccessToken, mpWebhookSecret] })
  .https.onRequest(async (req, res) => {

    // 1. Validate signature
    const secret = mpWebhookSecret.value().trim();
    if (!secret) {
      functions.logger.error("MP_WEBHOOK_SECRET is not configured. Rejecting all webhook requests.");
      res.status(500).send("Server misconfiguration");
      return;
    }
    if (!validateSignature(req, secret)) {
      functions.logger.warn("Invalid MP webhook signature — rejected.");
      res.status(401).send("Unauthorized");
      return;
    }

    try {
      const topic = (req.query.topic || req.body?.type) as string;
      const id = (req.query.id || req.body?.data?.id) as string;

      if (!id) {
        res.status(400).send("Missing ID");
        return;
      }

      functions.logger.info(`Webhook received: topic=${topic}, id=${id}`);

      // 2. Idempotency check
      if (await isAlreadyProcessed(`${topic}:${id}`)) {
        functions.logger.info(`Event ${topic}:${id} already processed. Skipping.`);
        res.status(200).send("OK - duplicate");
        return;
      }

      const client = new MercadoPagoConfig({ accessToken: mpAccessToken.value().trim() });

      // ────── Subscription linked/updated ──────
      if (topic === "subscription_preapproval") {
        const preApprovalClient = new PreApproval(client);
        const preapproval = await preApprovalClient.get({ id });

        const uid = preapproval.external_reference;
        const mpStatus = preapproval.status;

        if (!uid) {
          functions.logger.error("No external_reference in preapproval — cannot identify user.");
          res.status(200).send("OK - no user found");
          return;
        }

        const providerSnap = await db.collection("providers").doc(uid).get();
        const providerData = providerSnap.data() || {};

        const newStatus = mapStatus(mpStatus);

        // Pending = user just clicked "subscribe" but hasn't paid yet.
        // Only link the preapproval ID so the payment webhook can find them later;
        // do NOT touch plan, status, or expiresAt (preserves trial data).
        if (newStatus === "pending") {
          await db.collection("providers").doc(uid).update({
            mpPreapprovalId: id,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          await markProcessed(`${topic}:${id}`);
          functions.logger.info(`Provider ${uid}: pending preapproval ${id} linked. Current plan preserved.`);
          res.status(200).send("OK");
          return;
        }

        const reasonRaw = preapproval.reason || "";
        const reasonPlan = reasonRaw.toLowerCase().includes("premium") ? "premium" : "basic";

        const currentExpiresAt = providerData.subscriptionExpiresAt?.toDate?.();
        const hasFutureExpiry =
          currentExpiresAt && currentExpiresAt.getTime() > Date.now();

        let planToSet = newStatus === "active" ? reasonPlan : "none";
        let expiresAt: admin.firestore.Timestamp | null =
          newStatus === "active"
            ? calculateExpiresAt((preapproval as any).next_payment_date)
            : null;
        let statusToSet = newStatus;

        // If cancellation happens mid-cycle, keep access until existing expiry
        if (mpStatus === "cancelled" && hasFutureExpiry) {
          planToSet = providerData.plan || "basic";
          expiresAt = providerData.subscriptionExpiresAt || null;
          statusToSet = "pastDue";
        }

        await db.collection("providers").doc(uid).update({
          subscriptionStatus: statusToSet,
          plan: planToSet,
          subscriptionExpiresAt: expiresAt,
          mpPreapprovalId: id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await markProcessed(`${topic}:${id}`);
        functions.logger.info(`Provider ${uid} updated: status=${statusToSet}, plan=${planToSet}, expiresAt=${expiresAt?.toDate()}`);
        res.status(200).send("OK");
        return;
      }

      // ────── Monthly payment authorized ──────
      if (topic === "subscription_authorized_payment") {
        // The id is an authorized_payment ID, NOT a regular payment ID.
        // Use the Invoice client (/authorized_payments endpoint).
        const invoiceClient = new Invoice(client);
        const authorizedPayment = await invoiceClient.get({ id });

        const paymentStatus = authorizedPayment.payment?.status;
        if (paymentStatus !== "approved") {
          functions.logger.info(`Authorized payment ${id} not approved (status: ${paymentStatus}). Ignoring.`);
          res.status(200).send("OK - not approved");
          return;
        }

        const preapprovalId = authorizedPayment.preapproval_id;
        if (!preapprovalId) {
          functions.logger.error(`No preapproval_id in authorized payment ${id}`);
          res.status(200).send("OK - no preapproval_id");
          return;
        }

        // Fetch preapproval for next_payment_date and as uid fallback
        const preApprovalClient = new PreApproval(client);
        const preapproval = await preApprovalClient.get({ id: preapprovalId });
        const newExpiresAt = calculateExpiresAt((preapproval as any).next_payment_date);

        // Primary: find provider by mpPreapprovalId
        // Fallback: use external_reference from preapproval
        const snapshot = await db.collection("providers")
          .where("mpPreapprovalId", "==", preapprovalId)
          .limit(1)
          .get();

        let providerRef: admin.firestore.DocumentReference;
        if (!snapshot.empty) {
          providerRef = snapshot.docs[0].ref;
        } else {
          const uid = preapproval.external_reference;
          if (!uid) {
            functions.logger.error(`No provider found and no external_reference in preapproval ${preapprovalId}`);
            res.status(200).send("OK - no provider found");
            return;
          }
          functions.logger.warn(`Provider not found by mpPreapprovalId — race condition fallback: uid=${uid}`);
          providerRef = db.collection("providers").doc(uid);
        }

        const reasonRaw = preapproval.reason || "";
        const reasonPlan = reasonRaw.toLowerCase().includes("premium") ? "premium" : "basic";

        await providerRef.update({
          subscriptionStatus: "active",
          plan: reasonPlan,
          subscriptionExpiresAt: newExpiresAt,
          mpPreapprovalId: preapprovalId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await markProcessed(`${topic}:${id}`);
        functions.logger.info(`Provider ${providerRef.id} renewed. plan=${reasonPlan}, expiresAt=${newExpiresAt.toDate()}`);
        res.status(200).send("OK");
        return;
      }

      res.status(200).send("Event type not handled");

    } catch (error) {
      functions.logger.error("Webhook processing error", error);
      res.status(500).send("Internal Server Error");
    }
  });
