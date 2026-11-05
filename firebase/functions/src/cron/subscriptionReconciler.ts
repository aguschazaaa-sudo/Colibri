import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { MercadoPagoConfig, PreApproval } from "mercadopago";

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");
const db = admin.firestore();
const GRACE_PERIOD_MS = 3 * 24 * 60 * 60 * 1000;

function mapStatus(mpStatus: string | undefined): string {
  switch (mpStatus) {
    case "authorized": return "active";
    case "pending":    return "pending";
    case "paused":     return "pastDue";
    case "cancelled":  return "suspended";
    default:           return "pastDue";
  }
}

function calculateExpiresAt(nextPaymentDate: string | null | undefined): admin.firestore.Timestamp {
  const base = nextPaymentDate
    ? new Date(nextPaymentDate).getTime()
    : Date.now() + 30 * 24 * 60 * 60 * 1000;
  return admin.firestore.Timestamp.fromDate(new Date(base + GRACE_PERIOD_MS));
}

export const subscriptionReconciler = functions
  .runWith({ secrets: [mpAccessToken] })
  .pubsub.schedule("0 */6 * * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async () => {
    const snapshot = await db
      .collection("providers")
      .where("mpPreapprovalId", "!=", null)
      .get();

    if (snapshot.empty) {
      functions.logger.info("[subscriptionReconciler] No subscriptions to reconcile.");
      return null;
    }

    const client = new MercadoPagoConfig({ accessToken: mpAccessToken.value().trim() });
    const preapprovalClient = new PreApproval(client);

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const mpPreapprovalId = data.mpPreapprovalId as string | undefined;
      if (!mpPreapprovalId) continue;

      try {
        const preapproval = await preapprovalClient.get({ id: mpPreapprovalId });
        const mpStatus = preapproval.status as string | undefined;
        const newStatus = mapStatus(mpStatus);

        // Pending preapprovals should not alter the provider's current plan/status.
        if (newStatus === "pending") continue;

        const reasonRaw = preapproval.reason || "";
        const reasonPlan = reasonRaw.toLowerCase().includes("premium") ? "premium" : "basic";

        const currentExpiresAt = data.subscriptionExpiresAt?.toDate?.();
        const hasFutureExpiry = currentExpiresAt && currentExpiresAt.getTime() > Date.now();

        let planToSet = newStatus === "active" ? reasonPlan : "none";
        let expiresAt: admin.firestore.Timestamp | null =
          newStatus === "active"
            ? calculateExpiresAt((preapproval as any).next_payment_date)
            : null;
        let statusToSet = newStatus;

        if (mpStatus === "cancelled" && hasFutureExpiry) {
          planToSet = data.plan || "basic";
          expiresAt = data.subscriptionExpiresAt || null;
          statusToSet = "pastDue";
        }

        await doc.ref.update({
          subscriptionStatus: statusToSet,
          plan: planToSet,
          subscriptionExpiresAt: expiresAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (error) {
        functions.logger.error("[subscriptionReconciler] Error reconciling", {
          providerId: doc.id,
          error,
        });
      }
    }

    return null;
  });
