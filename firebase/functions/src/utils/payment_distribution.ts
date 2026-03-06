import * as admin from "firebase-admin";

/**
 * Distributes a given amount of money across unpaid appointments using FIFO.
 * Modifies the documents in the provided transaction.
 *
 * @param transaction The current Firestore transaction.
 * @param amountToDistribute The total amount to distribute.
 * @param unpaidAppointments An array of unpaid appointment QueryDocumentSnapshots, ordered by date.
 * @param specificAppointmentId Optional. If provided, only applies money to this specific appointment.
 * @returns An object containing the total debt decrease and the leftover money for the balance.
 */
export function distributePaymentFIFO(
  transaction: admin.firestore.Transaction,
  amountToDistribute: number,
  unpaidAppointments: admin.firestore.QueryDocumentSnapshot<admin.firestore.DocumentData>[],
  specificAppointmentId?: string | null
): { totalDebtDecrease: number; leftoverBalance: number } {
  let moneyLeftToDistribute = amountToDistribute;
  let totalDebtDecrease = 0;

  const targetDocs = specificAppointmentId
    ? unpaidAppointments.filter((doc) => doc.id === specificAppointmentId)
    : unpaidAppointments;

  for (const doc of targetDocs) {
    if (moneyLeftToDistribute <= 0) break;

    const appData = doc.data();
    const pendingAmount = appData.totalAmount - (appData.amountPaid || 0);

    if (pendingAmount > 0) {
      const amountToApply = Math.min(moneyLeftToDistribute, pendingAmount);
      const newAmountPaid = (appData.amountPaid || 0) + amountToApply;
      const newStatus = newAmountPaid >= appData.totalAmount ? "liquidated" : "unpaid";

      transaction.update(doc.ref, {
        amountPaid: newAmountPaid,
        status: newStatus,
      });

      moneyLeftToDistribute -= amountToApply;
      totalDebtDecrease += amountToApply;
    }
  }

  return {
    totalDebtDecrease,
    leftoverBalance: moneyLeftToDistribute,
  };
}

/**
 * Reverts a given amount of money from paid/partially paid appointments using Reverse FIFO (LIFO).
 * Des-pays the most recent appointments first.
 * Modifies the documents in the provided transaction.
 *
 * @param transaction The current Firestore transaction.
 * @param amountToRevert The total amount to revert.
 * @param paidAppointments An array of appointment QueryDocumentSnapshots with amountPaid > 0, ordered by date DESCENDING.
 * @returns An object containing the total debt increase.
 */
export function revertPaymentLIFO(
  transaction: admin.firestore.Transaction,
  amountToRevert: number,
  paidAppointments: admin.firestore.QueryDocumentSnapshot<admin.firestore.DocumentData>[]
): { totalDebtIncrease: number } {
  let moneyLeftToRevert = amountToRevert;
  let totalDebtIncrease = 0;

  for (const doc of paidAppointments) {
    if (moneyLeftToRevert <= 0) break;

    const appData = doc.data();
    const amountPaid = appData.amountPaid || 0;

    if (amountPaid > 0) {
      const amountToDeduct = Math.min(moneyLeftToRevert, amountPaid);
      const newAmountPaid = amountPaid - amountToDeduct;
      const newStatus = newAmountPaid >= appData.totalAmount ? "liquidated" : "unpaid";

      transaction.update(doc.ref, {
        amountPaid: newAmountPaid,
        status: newStatus,
      });

      moneyLeftToRevert -= amountToDeduct;
      totalDebtIncrease += amountToDeduct;
    }
  }

  return {
    totalDebtIncrease,
  };
}
