import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { MercadoPagoConfig, PreApproval } from "mercadopago";

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");

export const cancelSubscription = functions
  .runWith({ secrets: [mpAccessToken] })
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in to cancel a subscription."
      );
    }

    const uid = context.auth.uid;
    const db = admin.firestore();

    const userDoc = await db.collection("providers").doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "User profile not found."
      );
    }
    const userData = userDoc.data();
    const preapprovalId = userData?.mpPreapprovalId as string | undefined;

    if (!preapprovalId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No active subscription found."
      );
    }

    const client = new MercadoPagoConfig({
      accessToken: mpAccessToken.value().trim(),
    });
    const preapproval = new PreApproval(client);

    try {
      await preapproval.update({
        id: preapprovalId,
        body: { status: "cancelled" },
      });
    } catch (error: any) {
      functions.logger.error("Error cancelling Mercado Pago subscription", {
        message: error.message,
        response: error.response?.data,
        stack: error.stack,
      });
      throw new functions.https.HttpsError(
        "internal",
        "Failed to cancel subscription.",
        error.message
      );
    }

    await db.collection("providers").doc(uid).update({
      subscriptionStatus: "pastDue",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true };
  });
