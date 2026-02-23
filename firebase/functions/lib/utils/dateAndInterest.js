"use strict";
/**
 * Pure utility functions for date computation and interest calculation.
 * Extracted from Cloud Functions for testability.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.isOlderThanMonths = exports.calculateInterest = exports.generateRecurringDates = exports.computeNextDate = exports.MONTHLY_INTEREST_RATE = void 0;
// Default interest rate: 5% per month (Compound)
exports.MONTHLY_INTEREST_RATE = 0.05;
/**
 * Computes the next date based on a frequency pattern.
 */
function computeNextDate(date, frequency) {
    const next = new Date(date);
    switch (frequency) {
        case "weekly":
            next.setDate(next.getDate() + 7);
            break;
        case "biweekly":
            next.setDate(next.getDate() + 14);
            break;
        case "monthly_28days":
            next.setDate(next.getDate() + 28);
            break;
        case "monthly_pattern": {
            // "Nth Weekday of the month" logic
            const targetDayOfWeek = date.getDay();
            const nThOccurrence = Math.ceil(date.getDate() / 7);
            const targetMonth = (date.getMonth() + 1) % 12;
            const targetYear = date.getMonth() === 11 ? date.getFullYear() + 1 : date.getFullYear();
            next.setFullYear(targetYear, targetMonth, 1);
            // Find the first occurrence of the target day of week in the new month
            let daysOffset = targetDayOfWeek - next.getDay();
            if (daysOffset < 0)
                daysOffset += 7;
            // Move to the Nth occurrence
            next.setDate(1 + daysOffset + (nThOccurrence - 1) * 7);
            // Edge case: if the 5th occurrence spills into the NEXT month, fallback to 4th
            if (next.getMonth() !== targetMonth) {
                next.setDate(next.getDate() - 7);
            }
            break;
        }
        default:
            throw new Error(`Unknown frequency: ${frequency}`);
    }
    return next;
}
exports.computeNextDate = computeNextDate;
/**
 * Generates a series of dates for recurring appointments.
 */
function generateRecurringDates(baseDate, frequency, occurrences) {
    const dates = [];
    let current = new Date(baseDate);
    for (let i = 0; i < occurrences; i++) {
        dates.push(new Date(current));
        current = computeNextDate(current, frequency);
    }
    return dates;
}
exports.generateRecurringDates = generateRecurringDates;
/**
 * Calculates compound interest on a pending amount.
 */
function calculateInterest(pendingAmount, rate = exports.MONTHLY_INTEREST_RATE) {
    return pendingAmount * rate;
}
exports.calculateInterest = calculateInterest;
/**
 * Checks if a date is older than N months from a reference date.
 */
function isOlderThanMonths(date, months, referenceDate = new Date()) {
    const threshold = new Date(referenceDate);
    threshold.setMonth(threshold.getMonth() - months);
    return date < threshold;
}
exports.isOlderThanMonths = isOlderThanMonths;
//# sourceMappingURL=dateAndInterest.js.map