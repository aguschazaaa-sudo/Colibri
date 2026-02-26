import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

/**
 * Triggered when a new user is created in Firebase Auth.
 * Automatically provisions an initial Provider document in Firestore.
 */
export const onCreateUser = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName } = user;

  const providerDoc = {
    id: uid,
    email: email || "",
    name: displayName || "",
    subscriptionStatus: "active",
    defaultMonthlyInterestRate: 0.0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    await admin.firestore().collection("providers").doc(uid).set(providerDoc);
    functions.logger.info(`Successfully created provider doc for user ${uid}`);
  } catch (error) {
    functions.logger.error(`Error creating provider doc for user ${uid}:`, error);
    // Let it fail (we could implement retry mechanisms or let it be if it's not critical, but for now log it)
  }
});
