import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { applyDashboardDeltaInTx } from "../utils/metrics_utils";
import { distributePaymentFIFO } from "../utils/payment_distribution";
import { enqueueUrgentAppointmentReminder } from "../utils/messaging_utils";

const db = admin.firestore();

/**
 * Compares the `_functionUpdatedAt` timestamp between before and after snapshots.
 * Returns true if the timestamp changed in this update, meaning the update was
 * performed by a Cloud Function (self-triggered) and should be skipped.
 *
 * This is more robust than a boolean flag because:
 * - No need to "clean up" the flag (which itself causes a re-trigger).
 * - Timestamp comparison is deterministic: if the value changed, it was us.
 */
function isSelfTriggeredUpdate(
  oldData: admin.firestore.DocumentData,
  newData: admin.firestore.DocumentData
): boolean {
  const oldTs = oldData._functionUpdatedAt;
  const newTs = newData._functionUpdatedAt;

  // If newTs exists and differs from oldTs, this update was made by a function.
  if (!newTs) return false;
  if (!oldTs) return true; // Was absent before, now present → function wrote it.

  // Both exist: compare millis. If they differ, function wrote it.
  const oldMillis = oldTs?.toMillis?.() ?? 0;
  const newMillis = newTs?.toMillis?.() ?? 0;
  return oldMillis !== newMillis;
}

/**
 * Firestore Trigger: onAppointmentUpdated
 *
 * Fires when an appointment's `totalAmount`, `date` or `status` changes
 * (self-triggered updates are skipped via `_functionUpdatedAt`).
 *
 * Responsibilities:
 *   1. Reverts the appointment's previous ledger impact and applies the new
 *      one (balance first, then debt), redistributing any freed balance FIFO.
 *   2. Updates the dashboard's `totalToCollect` by exactly
 *      `newTotalDebt - currentTotalDebt`, inside the same transaction
 *      (atomic, retry-safe). Balance changes never touch the dashboard.
 *   3. Cancels / re-enqueues appointment reminders when the date changes.
 */
export const onAppointmentUpdated = functions
  .runWith({ maxInstances: 10 })
  .firestore.document(
    "providers/{providerId}/patients/{patientId}/appointments/{appointmentId}"
  )
  .onUpdate(async (change, context) => {
    const { providerId, patientId, appointmentId } = context.params;
    const oldData = change.before.data();
    const newData = change.after.data();

    if (!oldData || !newData) return;

    // ── GUARDRAIL: prevent infinite loops ──
    // If `_functionUpdatedAt` changed in this update, a Cloud Function wrote it.
    // Bail out immediately to prevent cascading re-triggers.
    if (isSelfTriggeredUpdate(oldData, newData)) {
      functions.logger.info(
        "[onAppointmentUpdated] Skipping self-triggered update (timestamp changed).",
        { appointmentId }
      );
      return;
    }

    const totalAmountChanged = oldData.totalAmount !== newData.totalAmount;
    const dateChanged = oldData.date?.toMillis() !== newData.date?.toMillis();
    const statusChanged = oldData.status !== newData.status;

    if (!totalAmountChanged && !dateChanged && !statusChanged) {
      functions.logger.info(
        "[onAppointmentUpdated] No relevant financial changes.",
        { appointmentId }
      );
      return;
    }

    const patientRef = db
      .collection("providers")
      .doc(providerId)
      .collection("patients")
      .doc(patientId);

    const appointmentRef = change.after.ref;

    try {
      await db.runTransaction(async (transaction) => {
        // NOTE: no state may leak out of this closure — Firestore re-runs it
        // on contention, so every value is recomputed per attempt.
        const patientDoc = await transaction.get(patientRef);
        if (!patientDoc.exists) return;

        const patientData = patientDoc.data()!;
        const currentTotalDebt: number = patientData.totalDebt || 0;
        const currentBalance: number = patientData.balance || 0;

        let workingDebt = currentTotalDebt;
        let workingBalance = currentBalance;

        const oldTotalAmount: number = oldData.totalAmount || 0;
        const oldAmountPaid: number = oldData.amountPaid || 0;
        const oldStatus = oldData.status;

        const newTotalAmount: number = newData.totalAmount || 0;
        let newAmountPaid: number = newData.amountPaid || 0;
        let newStatus = newData.status;

        const appointmentDate: admin.firestore.Timestamp = newData.date;
        const now = new Date();
        const isFuture = appointmentDate?.toDate
          ? appointmentDate.toDate() > now
          : false;

        if (isFuture) {
          newStatus = "scheduled";
        } else if (newStatus === "scheduled" && !isFuture) {
          newStatus = "unpaid"; // Before applying balance
        }

        // --- 1. REVERT OLD IMPACT ---
        if (oldStatus !== "scheduled") {
          const oldPendingDebt = Math.max(0, oldTotalAmount - oldAmountPaid);
          workingDebt = Math.max(0, workingDebt - oldPendingDebt);
          if (oldAmountPaid > 0) {
            workingBalance += oldAmountPaid;
          }
        }

        // --- 2. APPLY NEW IMPACT ---
        if (newStatus === "scheduled") {
          newAmountPaid = 0;
        } else {
          if (workingBalance >= newTotalAmount) {
            newAmountPaid = newTotalAmount;
            workingBalance -= newTotalAmount;
            newStatus = "liquidated";
          } else if (workingBalance > 0) {
            newAmountPaid = workingBalance;
            workingDebt += newTotalAmount - workingBalance;
            workingBalance = 0;
            newStatus = "unpaid";
          } else {
            newAmountPaid = 0;
            workingDebt += newTotalAmount;
            newStatus = "unpaid";
          }
        }

        // --- 3. REDISTRIBUTE LEFTOVER BALANCE ---
        if (workingBalance > currentBalance) {
          const amountToRedistribute = workingBalance - currentBalance;
          const appointmentsQuery = patientRef
            .collection("appointments")
            .where("providerId", "==", providerId)
            .where("status", "==", "unpaid")
            .orderBy("date", "asc");

          const unpaidSnapshot = await transaction.get(appointmentsQuery);
          const otherUnpaidDocs = unpaidSnapshot.docs.filter(
            (d) => d.id !== appointmentId
          );

          if (otherUnpaidDocs.length > 0) {
            const { totalDebtDecrease, leftoverBalance } =
              distributePaymentFIFO(
                transaction,
                amountToRedistribute,
                otherUnpaidDocs
              );
            workingDebt = Math.max(0, workingDebt - totalDebtDecrease);
            workingBalance = currentBalance + leftoverBalance;
          }
        }

        // --- Write back to patient and appointment ---
        if (
          workingDebt !== currentTotalDebt ||
          workingBalance !== currentBalance
        ) {
          transaction.update(patientRef, {
            totalDebt: workingDebt,
            balance: workingBalance,
          });

          // Dashboard `totalToCollect` == sum(patient.totalDebt), so its delta
          // is exactly the change written to totalDebt. The balance (saldo a
          // favor) is NOT part of totalToCollect: e.g. a prepaid scheduled
          // appointment activated to "unpaid" and covered by balance leaves
          // totalDebt unchanged and must not move the dashboard.
          applyDashboardDeltaInTx(transaction, providerId, {
            totalToCollect: workingDebt - currentTotalDebt,
          });
        }

        // Only write to the appointment if something actually changed.
        // Stamp `_functionUpdatedAt` so the next trigger invocation detects
        // this was a self-triggered update and bails out.
        if (newAmountPaid !== newData.amountPaid || newStatus !== newData.status) {
          transaction.update(appointmentRef, {
            amountPaid: newAmountPaid,
            status: newStatus,
            _functionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        // NOTE: If nothing changed on the appointment, we do NOT write anything.
        // The old code had an `else` block that deleted the flag, which itself
        // triggered another update and caused an infinite loop.
      });

      // ── Message queue: cancel and re-enqueue when appointment date changes ──
      if (dateChanged) {
        try {
          // Cancel any queued reminder for this appointment
          const queueSnap = await db
            .collection("message_queue")
            .where("providerId", "==", providerId)
            .where("sourceAppointmentId", "==", appointmentId)
            .where("status", "==", "queued")
            .get();

          if (!queueSnap.empty) {
            const cancelBatch = db.batch();
            for (const doc of queueSnap.docs) {
              cancelBatch.update(doc.ref, { status: "cancelled" });
            }
            await cancelBatch.commit();
          }

          // Re-enqueue if new date is in the future and within 48h
          const newApptDate = newData.date?.toDate?.();
          if (newApptDate) {
            const now = new Date();
            const hoursUntil =
              (newApptDate.getTime() - now.getTime()) / (1000 * 60 * 60);

            if (hoursUntil >= 2 && hoursUntil < 48) {
              // Check provider is still premium active
              const providerDoc = await db
                .collection("providers")
                .doc(providerId)
                .get();
              const provData = providerDoc.data();

              if (
                provData &&
                provData.subscriptionStatus === "active" &&
                provData.plan === "premium"
              ) {
                const patDoc = await db
                  .collection("providers")
                  .doc(providerId)
                  .collection("patients")
                  .doc(patientId)
                  .get();
                const patientName = patDoc.data()?.name ?? "";

                await enqueueUrgentAppointmentReminder(
                  appointmentId,
                  { date: newData.date, concept: newData.concept },
                  { name: provData.name, profession: provData.profession },
                  providerId,
                  patientId,
                  patientName
                );

                functions.logger.info(
                  "[onAppointmentUpdated] Re-enqueued urgent reminder after date change",
                  { appointmentId, hoursUntil: Math.round(hoursUntil) }
                );
              }
            }
          }
        } catch (queueError) {
          functions.logger.warn(
            "[onAppointmentUpdated] Failed to update message queue after date change",
            { appointmentId, error: String(queueError) }
          );
        }
      }
    } catch (error) {
      functions.logger.error(
        "[onAppointmentUpdated] Transaction failed:",
        { appointmentId, error: String(error) }
      );
      throw error;
    }
  });
