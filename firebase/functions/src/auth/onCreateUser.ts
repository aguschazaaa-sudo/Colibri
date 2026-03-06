import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

/**
 * Triggered when a new user is created in Firebase Auth.
 * Automatically provisions an initial Provider document in Firestore.
 */
export const onCreateUser = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName } = user;

  const now = admin.firestore.Timestamp.now();
  const expiresAt = new admin.firestore.Timestamp(now.seconds + 5 * 24 * 60 * 60, now.nanoseconds);

  const providerDoc: any = {
    id: uid,
    email: email || "",
    subscriptionStatus: "active",
    plan: "basic",
    subscriptionExpiresAt: expiresAt,
    defaultMonthlyInterestRate: 0.0,
    nonWorkingDays: ['01-01', '03-24', '04-02', '05-01', '05-25', '06-20', '07-09', '12-08', '12-25'],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (displayName) {
    providerDoc.name = displayName;
  }

  try {
    await admin.firestore().collection("providers").doc(uid).set(providerDoc, { merge: true });
    functions.logger.info(`Successfully created provider doc for user ${uid}`);
  } catch (error) {
    functions.logger.error(`Error creating provider doc for user ${uid}:`, error);
    // Let it fail (we could implement retry mechanisms or let it be if it's not critical, but for now log it)
  }
});
