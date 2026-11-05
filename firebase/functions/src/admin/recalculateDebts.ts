import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { roundCents } from "../utils/debt_calculation";
import { recalculatePatientDebt } from "../utils/recalculate_patient_debt";
import { getDashboardRef } from "../utils/metrics_utils";

const db = admin.firestore();

/**
 * Callable: recalculateDebts
 *
 * Repairs `totalDebt` for every patient of the calling provider by recomputing
 * it from the unpaid appointments, then rebuilds dashboard `totalToCollect`
 * as an absolute sum (not a delta), since it accumulated the same drift.
 *
 * Idempotent: safe to run any number of times.
 * Multi-tenant: only touches providers/{context.auth.uid}.
 */
export const recalculateDebts = functions
  .runWith({ timeoutSeconds: 300 })
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "El usuario no está autenticado.",
      );
    }
    const providerId = context.auth.uid;

    const patientsSnapshot = await db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .get();

    let fixed = 0;
    let totalToCollect = 0;

    // Sequential on purpose: one small transaction per patient, no contention
    // between them and predictable load on Firestore.
    for (const patientDoc of patientsSnapshot.docs) {
      const result = await recalculatePatientDebt(db, patientDoc.ref);
      if (!result) continue;
      if (result.delta !== 0) fixed++;
      totalToCollect += result.newDebt;
    }

    await getDashboardRef(providerId).set(
      {
        totalToCollect: roundCents(totalToCollect),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log(
      `[recalculateDebts] Provider ${providerId}: ${fixed}/${patientsSnapshot.size} patients corrected.`
    );

    return { patients: patientsSnapshot.size, fixed };
  });
