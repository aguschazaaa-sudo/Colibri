import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  enqueueMessage,
  formatCurrency,
  formatDebtDetail,
} from "../utils/messaging_utils";

const db = admin.firestore();

/**
 * Cron Job that runs on the 1st of every month at 16:00 Buenos Aires time
 * (1 hour after monthlyDebtProcessor to ensure interest is already applied).
 *
 * Iterates over all providers with subscriptionStatus == "active" and
 * plan in ["basic", "premium", "trial"], then for each patient with
 * totalDebt > 0 queries their unpaid appointments to build a detailed
 * payment_reminder WhatsApp message.
 *
 * No PII is logged. Internal doc IDs may appear in warn logs for diagnostics.
 */
export const monthlyDebtNotifier = functions
  .runWith({ maxInstances: 10 })
  .pubsub.schedule("0 16 1 * *")
  .timeZone("America/Argentina/Buenos_Aires")
  .onRun(async () => {
    functions.logger.info("[monthlyDebtNotifier] Started");

    const now = new Date();

    // Derive month key in Buenos Aires timezone for idempotency
    const baDate = new Date(now.toLocaleString("en-US", { timeZone: "America/Argentina/Buenos_Aires" }));
    const monthKey = `${baDate.getFullYear()}-${String(baDate.getMonth() + 1).padStart(2, "0")}`;

    // Query providers with active subscription (basic, premium, trial)
    const [basicSnap, premiumSnap, trialSnap] = await Promise.all([
      db
        .collection("providers")
        .where("subscriptionStatus", "==", "active")
        .where("plan", "==", "basic")
        .get(),
      db
        .collection("providers")
        .where("subscriptionStatus", "==", "active")
        .where("plan", "==", "premium")
        .get(),
      db
        .collection("providers")
        .where("subscriptionStatus", "==", "active")
        .where("plan", "==", "trial")
        .get(),
    ]);

    const allProviderDocs = [
      ...basicSnap.docs,
      ...premiumSnap.docs,
      ...trialSnap.docs,
    ];

    if (allProviderDocs.length === 0) {
      functions.logger.info("[monthlyDebtNotifier] No eligible providers found.");
      return null;
    }

    functions.logger.info("[monthlyDebtNotifier] Processing providers", {
      count: allProviderDocs.length,
    });

    for (const providerDoc of allProviderDocs) {
      const providerId = providerDoc.id;
      const providerData = providerDoc.data();
      const providerName: string = providerData.name ?? "";
      const providerProfession: string = providerData.profession ?? "";
      const profesionalProfesion = [providerProfession, providerName]
        .filter(Boolean)
        .join(" ");

      // Query patients with totalDebt > 0 for this provider
      const patientsSnap = await db
        .collection("providers")
        .doc(providerId)
        .collection("patients")
        .where("totalDebt", ">", 0)
        .get();

      if (patientsSnap.empty) {
        continue;
      }

      for (const patientDoc of patientsSnap.docs) {
        const patientData = patientDoc.data();
        const patientName: string = patientData.name ?? "";
        const totalDebt: number = patientData.totalDebt ?? 0;

        if (totalDebt <= 0) continue;

        // Query unpaid appointments for this patient, ordered by date desc
        const unpaidSnap = await db
          .collection("providers")
          .doc(providerId)
          .collection("patients")
          .doc(patientDoc.id)
          .collection("appointments")
          .where("status", "==", "unpaid")
          .orderBy("date", "desc")
          .get();

        const appointmentItems = unpaidSnap.docs
          .map((d) => {
            const data = d.data();
            const ts: admin.firestore.Timestamp | undefined = data.date;
            if (!ts?.toDate) return null;
            const totalAmount: number = data.totalAmount ?? 0;
            const amountPaid: number = data.amountPaid ?? 0;
            const pending = totalAmount - amountPaid;
            if (pending <= 0) return null;
            return { date: ts.toDate(), amount: pending };
          })
          .filter((x): x is { date: Date; amount: number } => x !== null);

        if (appointmentItems.length === 0) continue;

        // Cross-validate: sum of appointments vs patient.totalDebt
        const sumFromAppointments = appointmentItems.reduce(
          (s, a) => s + a.amount,
          0
        );
        if (Math.abs(sumFromAppointments - totalDebt) > 1) {
          functions.logger.warn(
            "[monthlyDebtNotifier] totalDebt discrepancy",
            {
              providerId,
              patientDocId: patientDoc.id, // not PII: internal doc ID
              // Amounts omitted from log to avoid logging financial PII
              discrepancyExists: true,
            }
          );
        }

        // Build template variables
        const { detalleOrigen, fechas } = formatDebtDetail(appointmentItems);
        const montoTotal = formatCurrency(sumFromAppointments);

        // Enqueue payment_reminder: priority 30, expires in 10 days
        const expiresAt = new Date(now);
        expiresAt.setDate(expiresAt.getDate() + 10);

        await enqueueMessage({
          providerId,
          patientId: patientDoc.id,
          patientName,
          messageType: "payment_reminder",
          variables: {
            nombre_paciente: patientName,
            profesional_profesion: profesionalProfesion,
            monto_total: montoTotal,
            detalle_origen: detalleOrigen,
            fechas,
          },
          priority: 30,
          isUrgent: false,
          scheduledFor: now,
          expiresAt,
          idempotencyKey: `pay_${providerId}_${patientDoc.id}_${monthKey}`,
        });
      }
    }

    functions.logger.info("[monthlyDebtNotifier] Finished");
    return null;
  });
