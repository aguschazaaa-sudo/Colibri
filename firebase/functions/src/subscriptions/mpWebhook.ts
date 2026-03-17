import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";
import { MercadoPagoConfig, PreApproval, Payment } from "mercadopago";

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
    const xRequestId = req.headers["x-request-id"] as string;
    const dataId = req.query["data.id"] as string;

    if (!xSignature) return false;

    const parts = xSignature.split(",");
    let ts = "";
    let v1 = "";
    for (const part of parts) {
      const [key, value] = part.split("=");
      if (key.trim() === "ts") ts = value.trim();
      if (key.trim() === "v1") v1 = value.trim();
    }

    if (!ts || !v1) return false;

    const signedTemplate = `id:${dataId};request-id:${xRequestId};ts:${ts};`;
    const computedHash = crypto
      .createHmac("sha256", secret)
      .update(signedTemplate)
      .digest("hex");

    return crypto.timingSafeEqual(
      Buffer.from(computedHash),
      Buffer.from(v1)
    );
  } catch (e) {
    functions.logger.warn("Signature validation error", e);
    return false;
  }
}

/** Maps a MercadoPago preapproval status to our internal subscription status. */
function mapStatus(mpStatus: string | undefined): string {
  switch (mpStatus) {
    case "authorized": return "active";
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
  if (snap.exists) return true;
  // Mark as processed
  await ref.set({ processedAt: admin.firestore.FieldValue.serverTimestamp() });
  return false;
}

export const mpWebhook = functions
  .runWith({ secrets: [mpAccessToken, mpWebhookSecret] })
  .https.onRequest(async (req, res) => {

    // 1. Validate signature
    const secret = mpWebhookSecret.value().trim();
    if (secret) {
      if (!validateSignature(req, secret)) {
        functions.logger.warn("Invalid MP webhook signature — rejected.");
        res.status(401).send("Unauthorized");
        return;
      }
    } else {
      functions.logger.warn("MP_WEBHOOK_SECRET not set. Skipping signature validation.");
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

        const newStatus = mapStatus(mpStatus);
        const reasonRaw = preapproval.reason || "";
        const plan = reasonRaw.startsWith("plan:") ? reasonRaw.split(":")[1] : "basic";

        // Use MP's next_payment_date + grace period instead of a fixed 30-day window
        const expiresAt = newStatus === "active"
          ? calculateExpiresAt((preapproval as any).next_payment_date)
          : null;

        await db.collection("providers").doc(uid).update({
          subscriptionStatus: newStatus,
          plan: newStatus === "active" ? plan : "none",
          subscriptionExpiresAt: expiresAt,
          mpPreapprovalId: id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        functions.logger.info(`Provider ${uid} updated: status=${newStatus}, plan=${plan}, expiresAt=${expiresAt?.toDate()}`);
        res.status(200).send("OK");
        return;
      }

      // ────── Monthly payment authorized ──────
      if (topic === "subscription_authorized_payment") {
        const paymentClient = new Payment(client);
        const payment = await paymentClient.get({ id });

        if (payment.status !== "approved") {
          functions.logger.info(`Payment ${id} not approved (status: ${payment.status}). Ignoring.`);
          res.status(200).send("OK - not approved");
          return;
        }

        const preapprovalId = (payment as any).metadata?.preapproval_id
          || (payment as any).preapproval_id;

        if (!preapprovalId) {
          functions.logger.error(`No preapproval_id found in payment ${id}`);
          res.status(200).send("OK - no preapproval_id");
          return;
        }

        // Find the provider by mpPreapprovalId
        const snapshot = await db.collection("providers")
          .where("mpPreapprovalId", "==", preapprovalId)
          .limit(1)
          .get();

        if (snapshot.empty) {
          functions.logger.error(`No provider found with mpPreapprovalId=${preapprovalId}`);
          res.status(200).send("OK - no provider found");
          return;
        }

        const providerRef = snapshot.docs[0].ref;

        // Extend subscription by 30 days + grace period from now
        const newExpiresAt = calculateExpiresAt(null);
        await providerRef.update({
          subscriptionStatus: "active",
          subscriptionExpiresAt: newExpiresAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        functions.logger.info(`Provider ${providerRef.id} renewed. New expiresAt: ${newExpiresAt.toDate()}`);
        res.status(200).send("OK");
        return;
      }

      res.status(200).send("Event type not handled");

    } catch (error) {
      functions.logger.error("Webhook processing error", error);
      res.status(500).send("Internal Server Error");
    }
  });
