import {
  affectsDebt,
  computeTotalDebt,
  pendingDebtOf,
  roundCents,
} from "../utils/debt_calculation";

describe("pendingDebtOf", () => {
  it("returns totalAmount - amountPaid for unpaid appointments", () => {
    expect(pendingDebtOf({ status: "unpaid", totalAmount: 1000, amountPaid: 300 })).toBe(700);
  });

  it("returns 0 for liquidated and cancelled appointments", () => {
    expect(pendingDebtOf({ status: "liquidated", totalAmount: 1000, amountPaid: 1000 })).toBe(0);
    expect(pendingDebtOf({ status: "cancelled", totalAmount: 1000, amountPaid: 0 })).toBe(0);
  });

  it("never returns negative debt when overpaid", () => {
    expect(pendingDebtOf({ status: "unpaid", totalAmount: 500, amountPaid: 800 })).toBe(0);
  });

  it("treats missing amountPaid as 0", () => {
    expect(pendingDebtOf({ status: "unpaid", totalAmount: 500 })).toBe(500);
  });

  it("treats missing/garbage totalAmount as 0", () => {
    expect(pendingDebtOf({ status: "unpaid" })).toBe(0);
    expect(pendingDebtOf({ status: "unpaid", totalAmount: NaN })).toBe(0);
  });
});

describe("computeTotalDebt", () => {
  it("returns 0 for an empty ledger", () => {
    expect(computeTotalDebt([])).toBe(0);
  });

  it("sums only unpaid pending amounts (matches 'Turnos sin pagar' list)", () => {
    const total = computeTotalDebt([
      { status: "unpaid", totalAmount: 10000, amountPaid: 0 },
      { status: "unpaid", totalAmount: 10000, amountPaid: 2500 },
      { status: "liquidated", totalAmount: 10000, amountPaid: 10000 },
      { status: "cancelled", totalAmount: 10000, amountPaid: 0 },
    ]);
    expect(total).toBe(17500);
  });

  it("rounds to cents to avoid float drift after compound interest", () => {
    const total = computeTotalDebt([
      { status: "unpaid", totalAmount: 0.1, amountPaid: 0 },
      { status: "unpaid", totalAmount: 0.2, amountPaid: 0 },
    ]);
    expect(total).toBe(0.3);
  });

  it("is idempotent: same input, same output", () => {
    const ledger = [{ status: "unpaid", totalAmount: 1050.5, amountPaid: 50.25 }];
    expect(computeTotalDebt(ledger)).toBe(computeTotalDebt(ledger));
  });
});

describe("roundCents", () => {
  it("rounds to 2 decimals", () => {
    expect(roundCents(0.1 + 0.2)).toBe(0.3);
    expect(roundCents(10.126)).toBe(10.13);
  });
});

describe("affectsDebt", () => {
  const base = { status: "unpaid", totalAmount: 1000, amountPaid: 0 };

  it("is true on create and delete", () => {
    expect(affectsDebt(undefined, base)).toBe(true);
    expect(affectsDebt(base, undefined)).toBe(true);
  });

  it("is true when an amount or the status changes", () => {
    expect(affectsDebt(base, { ...base, amountPaid: 500 })).toBe(true);
    expect(affectsDebt(base, { ...base, totalAmount: 1050 })).toBe(true);
    expect(affectsDebt(base, { ...base, status: "liquidated" })).toBe(true);
  });

  it("is false when only non-financial fields change", () => {
    expect(
      affectsDebt(
        { ...base, concept: "Consulta" } as never,
        { ...base, concept: "Control" } as never
      )
    ).toBe(false);
  });
});
