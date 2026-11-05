import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { MercadoPagoConfig, PreApproval } from "mercadopago";

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");

export const changePlan = functions
  .runWith({ secrets: [mpAccessToken] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in to change a subscription."
      );
    }

    const userEmail = context.auth.token.email;
    if (!userEmail) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "El usuario debe tener un email validado para suscribirse."
      );
    }

    const { planId, payerEmail } = data;
    if (planId !== "basic" && planId !== "premium") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid plan specified."
      );
    }

    const uid = context.auth.uid;
    const db = admin.firestore();

    // 1. Get Pricing
    const pricingDoc = await db.collection("metadata").doc("pricing").get();
    if (!pricingDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Pricing metadata not found."
      );
    }
    const pricingData = pricingDoc.data();
    const basePriceArs = planId === "basic"
      ? pricingData?.basic?.priceArs || 10000
      : pricingData?.premium?.priceArs || 20000;

    // 2. Get User Discount and current subscription
    const userDoc = await db.collection("providers").doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "User profile not found."
      );
    }
    const userData = userDoc.data();
    const discountPercentage = userData?.discountPercentage || 0.0;
    const existingPreapprovalId = userData?.mpPreapprovalId as string | undefined;

    const finalPrice = Math.round(basePriceArs * (1 - discountPercentage));

    // Use MP email from client if provided, otherwise fall back to Auth email
    const emailToUse = payerEmail && typeof payerEmail === "string" && payerEmail.trim()
      ? payerEmail.trim()
      : userEmail;

    // 3. Init Mercado Pago
    const client = new MercadoPagoConfig({
      accessToken: mpAccessToken.value().trim(),
    });
    const preapproval = new PreApproval(client);

    // 4. Cancel current preapproval if exists
    if (existingPreapprovalId) {
      try {
        await preapproval.update({
          id: existingPreapprovalId,
          body: { status: "cancelled" },
        });
      } catch (error: any) {
        functions.logger.warn("Failed to cancel existing preapproval", {
          message: error.message,
          response: error.response?.data,
        });
      }
    }

    // 5. Create new preapproval
    const response = await preapproval.create({
      body: {
        payer_email: emailToUse,
        back_url: "https://colibrimd.com.ar",
        reason: planId === "premium" ? "Plan Premium - ColibriMD" : "Plan Básico - ColibriMD",
        auto_recurring: {
          frequency: 1,
          frequency_type: "months",
          transaction_amount: finalPrice,
          currency_id: "ARS",
        },
        external_reference: uid,
        status: "pending",
      },
    });

    // 6. Update provider doc
    await db.collection("providers").doc(uid).update({
      subscriptionStatus: "pastDue",
      plan: planId,
      mpPreapprovalId: response.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      init_point: response.init_point,
      id: response.id,
    };
  });
