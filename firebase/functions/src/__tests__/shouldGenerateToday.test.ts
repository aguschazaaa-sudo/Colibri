import {
  shouldGenerateToday,
  toDateKey,
} from "../utils/dateAndInterest";

describe("toDateKey", () => {
  it("should format single-digit months and days with leading zeros", () => {
    expect(toDateKey(new Date(2026, 0, 5))).toBe("2026-01-05");
  });

  it("should format double-digit months and days correctly", () => {
    expect(toDateKey(new Date(2026, 11, 25))).toBe("2026-12-25");
  });
});

describe("shouldGenerateToday", () => {
  describe("weekly", () => {
    it("should return true when today is exactly 1 week after baseDate", () => {
      const baseDate = new Date(2026, 2, 2); // Mon Mar 2
      const today = new Date(2026, 2, 9); // Mon Mar 9 (1 week later)
      expect(shouldGenerateToday(baseDate, "weekly", today)).toBe(true);
    });

    it("should return true when today is exactly 3 weeks after baseDate", () => {
      const baseDate = new Date(2026, 2, 2);
      const today = new Date(2026, 2, 23); // 3 weeks later
      expect(shouldGenerateToday(baseDate, "weekly", today)).toBe(true);
    });

    it("should return false when today is 3 days after baseDate", () => {
      const baseDate = new Date(2026, 2, 2);
      const today = new Date(2026, 2, 5); // Wed (not a match)
      expect(shouldGenerateToday(baseDate, "weekly", today)).toBe(false);
    });

    it("should return true when today IS the baseDate", () => {
      const baseDate = new Date(2026, 2, 2);
      const today = new Date(2026, 2, 2);
      expect(shouldGenerateToday(baseDate, "weekly", today)).toBe(true);
    });
  });

  describe("biweekly", () => {
    it("should return true on the 2nd occurrence (14 days later)", () => {
      const baseDate = new Date(2026, 0, 5); // Mon Jan 5
      const today = new Date(2026, 0, 19); // Mon Jan 19
      expect(shouldGenerateToday(baseDate, "biweekly", today)).toBe(true);
    });

    it("should return false at 7 days (mid-point of biweekly)", () => {
      const baseDate = new Date(2026, 0, 5);
      const today = new Date(2026, 0, 12); // 7 days later
      expect(shouldGenerateToday(baseDate, "biweekly", today)).toBe(false);
    });
  });

  describe("monthly_28days", () => {
    it("should return true 28 days later", () => {
      const baseDate = new Date(2026, 0, 7); // Wed Jan 7
      const today = new Date(2026, 1, 4); // Wed Feb 4 (28 days later)
      expect(shouldGenerateToday(baseDate, "monthly_28days", today)).toBe(true);
    });

    it("should return false 30 days later", () => {
      const baseDate = new Date(2026, 0, 7);
      const today = new Date(2026, 1, 6); // 30 days later
      expect(shouldGenerateToday(baseDate, "monthly_28days", today)).toBe(false);
    });
  });

  describe("with lastGeneratedDate", () => {
    it("should skip already-generated dates and match the next one", () => {
      const baseDate = new Date(2026, 2, 2); // Mon Mar 2
      const lastGenerated = new Date(2026, 2, 9); // Already generated Mar 9
      const today = new Date(2026, 2, 16); // Next occurrence: Mar 16
      expect(shouldGenerateToday(baseDate, "weekly", today, lastGenerated)).toBe(true);
    });

    it("should return false if today was already the lastGeneratedDate", () => {
      const baseDate = new Date(2026, 2, 2);
      const lastGenerated = new Date(2026, 2, 9);
      const today = new Date(2026, 2, 9); // Same as lastGenerated
      // Next after lastGenerated is Mar 16, not Mar 9
      expect(shouldGenerateToday(baseDate, "weekly", today, lastGenerated)).toBe(false);
    });

    it("should return false for a date between occurrences", () => {
      const baseDate = new Date(2026, 2, 2);
      const lastGenerated = new Date(2026, 2, 9);
      const today = new Date(2026, 2, 12); // Wed, not a match
      expect(shouldGenerateToday(baseDate, "weekly", today, lastGenerated)).toBe(false);
    });
  });

  describe("edge cases", () => {
    it("should return false when today is before baseDate", () => {
      const baseDate = new Date(2026, 5, 1); // June 1 (future)
      const today = new Date(2026, 2, 2); // March 2 (past)
      expect(shouldGenerateToday(baseDate, "weekly", today)).toBe(false);
    });

    it("should handle crossing year boundaries", () => {
      const baseDate = new Date(2026, 11, 28); // Mon Dec 28
      const today = new Date(2027, 0, 4); // Mon Jan 4 (1 week later)
      expect(shouldGenerateToday(baseDate, "weekly", today)).toBe(true);
    });
  });
});
