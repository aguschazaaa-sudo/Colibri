"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const dateAndInterest_1 = require("../utils/dateAndInterest");
describe("computeNextDate", () => {
    describe("weekly", () => {
        it("should add exactly 7 days", () => {
            const base = new Date(2026, 1, 23); // Mon Feb 23
            const next = (0, dateAndInterest_1.computeNextDate)(base, "weekly");
            expect(next.getDate()).toBe(2); // Mar 2
            expect(next.getMonth()).toBe(2); // March
            expect(next.getDay()).toBe(base.getDay()); // Same day of week
        });
        it("should cross year boundaries correctly", () => {
            const base = new Date(2026, 11, 28); // Mon Dec 28
            const next = (0, dateAndInterest_1.computeNextDate)(base, "weekly");
            expect(next.getFullYear()).toBe(2027);
            expect(next.getMonth()).toBe(0); // January
            expect(next.getDate()).toBe(4);
        });
    });
    describe("biweekly", () => {
        it("should add exactly 14 days", () => {
            const base = new Date(2026, 1, 10); // Tue Feb 10
            const next = (0, dateAndInterest_1.computeNextDate)(base, "biweekly");
            expect(next.getDate()).toBe(24);
            expect(next.getMonth()).toBe(1); // Still Feb
            expect(next.getDay()).toBe(base.getDay());
        });
        it("should cross month boundaries", () => {
            const base = new Date(2026, 1, 20); // Feb 20
            const next = (0, dateAndInterest_1.computeNextDate)(base, "biweekly");
            expect(next.getMonth()).toBe(2); // March
            expect(next.getDate()).toBe(6);
        });
    });
    describe("monthly_28days", () => {
        it("should always add exactly 28 days", () => {
            const base = new Date(2026, 0, 5); // Mon Jan 5
            const next = (0, dateAndInterest_1.computeNextDate)(base, "monthly_28days");
            expect(next.getDate()).toBe(2); // Feb 2
            expect(next.getMonth()).toBe(1);
            expect(next.getDay()).toBe(base.getDay()); // Same day of week always
        });
        it("should keep the same day of the week across multiple jumps", () => {
            let current = new Date(2026, 0, 7); // Wed Jan 7
            const originalDayOfWeek = current.getDay();
            for (let i = 0; i < 12; i++) {
                current = (0, dateAndInterest_1.computeNextDate)(current, "monthly_28days");
                expect(current.getDay()).toBe(originalDayOfWeek);
            }
        });
    });
    describe("monthly_pattern (Nth weekday of the month)", () => {
        it("should find the 2nd Tuesday of March given 2nd Tuesday of February", () => {
            // Feb 10, 2026 is a Tuesday (2nd Tuesday of Feb)
            const base = new Date(2026, 1, 10);
            expect(base.getDay()).toBe(2); // Tuesday
            expect(Math.ceil(base.getDate() / 7)).toBe(2); // 2nd occurrence
            const next = (0, dateAndInterest_1.computeNextDate)(base, "monthly_pattern");
            expect(next.getMonth()).toBe(2); // March
            expect(next.getDay()).toBe(2); // Tuesday
            expect(Math.ceil(next.getDate() / 7)).toBe(2); // 2nd occurrence
        });
        it("should find the 1st Monday of next month", () => {
            // Jan 5, 2026 is a Monday (1st Monday of January)
            const base = new Date(2026, 0, 5);
            expect(base.getDay()).toBe(1); // Monday
            const next = (0, dateAndInterest_1.computeNextDate)(base, "monthly_pattern");
            expect(next.getMonth()).toBe(1); // February
            expect(next.getDay()).toBe(1); // Monday
            expect(Math.ceil(next.getDate() / 7)).toBe(1); // 1st occurrence
        });
        it("should handle the 5th occurrence by falling back to the 4th", () => {
            // Jan 29, 2026 is a Thursday (5th Thursday of January)
            const base = new Date(2026, 0, 29);
            expect(base.getDay()).toBe(4); // Thursday
            expect(Math.ceil(base.getDate() / 7)).toBe(5); // 5th occurrence
            const next = (0, dateAndInterest_1.computeNextDate)(base, "monthly_pattern");
            expect(next.getMonth()).toBe(1); // February
            expect(next.getDay()).toBe(4); // Thursday
            // Feb 2026 has only 4 Thursdays (5, 12, 19, 26), so the 5th doesn't exist
            // We expect fallback to the 4th Thursday: Feb 26
            expect(next.getDate()).toBe(26);
        });
        it("should maintain pattern across a full year", () => {
            // Start with the 3rd Wednesday of January 2026
            // Jan 21, 2026 = 3rd Wednesday
            let current = new Date(2026, 0, 21);
            expect(current.getDay()).toBe(3); // Wednesday
            for (let i = 0; i < 11; i++) {
                const prev = new Date(current);
                current = (0, dateAndInterest_1.computeNextDate)(current, "monthly_pattern");
                // Should always be a Wednesday
                expect(current.getDay()).toBe(3);
                // Should be the next month
                expect(current.getMonth()).toBe((prev.getMonth() + 1) % 12);
            }
        });
    });
    it("should throw on unknown frequency", () => {
        expect(() => (0, dateAndInterest_1.computeNextDate)(new Date(), "daily")).toThrow("Unknown frequency");
    });
});
describe("generateRecurringDates", () => {
    it("should generate the correct number of dates", () => {
        const base = new Date(2026, 0, 1);
        const dates = (0, dateAndInterest_1.generateRecurringDates)(base, "weekly", 4);
        expect(dates).toHaveLength(4);
    });
    it("should include the base date as the first date", () => {
        const base = new Date(2026, 0, 1);
        const dates = (0, dateAndInterest_1.generateRecurringDates)(base, "weekly", 3);
        expect(dates[0].getTime()).toBe(base.getTime());
    });
    it("should generate 12 monthly_28days dates preserving day of week", () => {
        const base = new Date(2026, 0, 7); // Wed
        const dates = (0, dateAndInterest_1.generateRecurringDates)(base, "monthly_28days", 12);
        expect(dates).toHaveLength(12);
        for (const d of dates) {
            expect(d.getDay()).toBe(3); // All Wednesdays
        }
    });
    it("should generate 12 monthly_pattern dates staying on the Nth weekday", () => {
        // 2nd Tuesday of Jan = Jan 13, 2026
        const base = new Date(2026, 0, 13);
        expect(base.getDay()).toBe(2); // Tuesday
        const dates = (0, dateAndInterest_1.generateRecurringDates)(base, "monthly_pattern", 12);
        expect(dates).toHaveLength(12);
        for (const d of dates) {
            expect(d.getDay()).toBe(2); // All Tuesdays
        }
    });
});
describe("calculateInterest", () => {
    it("should calculate 5% interest on 10000", () => {
        const interest = (0, dateAndInterest_1.calculateInterest)(10000);
        expect(interest).toBe(500); // 10000 * 0.05
    });
    it("should calculate custom rate", () => {
        const interest = (0, dateAndInterest_1.calculateInterest)(10000, 0.10);
        expect(interest).toBe(1000);
    });
    it("should return 0 for 0 pending amount", () => {
        expect((0, dateAndInterest_1.calculateInterest)(0)).toBe(0);
    });
    it("should simulate compound interest over 3 months", () => {
        let totalAmount = 10000;
        const amountPaid = 0;
        // Month 1
        const pending1 = totalAmount - amountPaid;
        const interest1 = (0, dateAndInterest_1.calculateInterest)(pending1);
        totalAmount += interest1;
        expect(totalAmount).toBeCloseTo(10500); // 10000 + 500
        // Month 2 (interest on interest)
        const pending2 = totalAmount - amountPaid;
        const interest2 = (0, dateAndInterest_1.calculateInterest)(pending2);
        totalAmount += interest2;
        expect(totalAmount).toBeCloseTo(11025); // 10500 + 525
        // Month 3
        const pending3 = totalAmount - amountPaid;
        const interest3 = (0, dateAndInterest_1.calculateInterest)(pending3);
        totalAmount += interest3;
        expect(totalAmount).toBeCloseTo(11576.25); // 11025 + 551.25
    });
});
describe("isOlderThanMonths", () => {
    it("should return true for dates older than 1 month", () => {
        const now = new Date(2026, 1, 28); // Feb 28
        const oldDate = new Date(2026, 0, 15); // Jan 15 (more than 1 month ago)
        expect((0, dateAndInterest_1.isOlderThanMonths)(oldDate, 1, now)).toBe(true);
    });
    it("should return false for recent dates", () => {
        const now = new Date(2026, 1, 28);
        const recentDate = new Date(2026, 1, 15); // Feb 15 (less than 1 month ago)
        expect((0, dateAndInterest_1.isOlderThanMonths)(recentDate, 1, now)).toBe(false);
    });
    it("should handle year boundaries", () => {
        const now = new Date(2026, 0, 28); // Jan 28, 2026
        const oldDate = new Date(2025, 10, 1); // Nov 1, 2025 (almost 3 months ago)
        expect((0, dateAndInterest_1.isOlderThanMonths)(oldDate, 1, now)).toBe(true);
        expect((0, dateAndInterest_1.isOlderThanMonths)(oldDate, 2, now)).toBe(true);
    });
    it("should return false for date exactly at the threshold", () => {
        const now = new Date(2026, 1, 28);
        const exactlyOneMonthAgo = new Date(2026, 0, 28); // Jan 28
        expect((0, dateAndInterest_1.isOlderThanMonths)(exactlyOneMonthAgo, 1, now)).toBe(false);
    });
});
//# sourceMappingURL=dateAndInterest.test.js.map