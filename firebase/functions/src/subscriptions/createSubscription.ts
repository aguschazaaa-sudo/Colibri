import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { MercadoPagoConfig, PreApproval } from "mercadopago";

const mpAccessToken = defineSecret("MP_ACCESS_TOKEN");

export const createSubscription = functions
  .runWith({ secrets: [mpAccessToken] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in to create a subscription."
      );
    }

    // Email is required — prevents MP fraud filters from blocking the account
    const userEmail = context.auth.token.email;
    if (!userEmail) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "El usuario debe tener un email validado para suscribirse."
      );
    }

    const { planId } = data; // 'basic' or 'premium'
    if (planId !== "basic" && planId !== "premium") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid plan specified."
      );
    }

    const uid = context.auth.uid;
    const db = admin.firestore();

    try {
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

      // 2. Get User Discount
      const userDoc = await db.collection("providers").doc(uid).get();
      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User profile not found."
        );
      }
      const userData = userDoc.data();
      const discountPercentage = userData?.discountPercentage || 0.0;
      
      // Calculate final price (e.g. 10000 * (1 - 0.20) = 8000)
      const finalPrice = Math.round(basePriceArs * (1 - discountPercentage));

      // 3. Init Mercado Pago
      const client = new MercadoPagoConfig({
        accessToken: mpAccessToken.value().trim(),
      });
      const preapproval = new PreApproval(client);

      // 4. Create Preapproval
      const response = await preapproval.create({
        body: {
          back_url: "https://colibrimd.com.ar",
          reason: `plan:${planId}`, // Used by webhook to identify the plan
          auto_recurring: {
            frequency: 1,
            frequency_type: "months",
            transaction_amount: finalPrice,
            currency_id: "ARS",
          },
          payer_email: userEmail,
          external_reference: uid,
          status: "pending",
        },
      });

      return {
        init_point: response.init_point,
        id: response.id,
      };

    } catch (error: any) {
      functions.logger.error("Error creating Mercado Pago subscription", {
        message: error.message,
        response: error.response?.data,
        cause: error.cause,
        stack: error.stack,
      });
      // We stringify the detailed error so it bubbles up exactly what failed
      const details = error.cause ? JSON.stringify(error.cause) : error.message;
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create subscription link.",
        details
      );
    }
  });
