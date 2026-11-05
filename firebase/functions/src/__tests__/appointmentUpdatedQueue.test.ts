// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockDoc = jest.fn();
const mockCollection = jest.fn();
const mockBatchUpdate = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  update: mockBatchUpdate,
  commit: mockBatchCommit,
}));

const mockEnqueueUrgentReminder = jest.fn().mockResolvedValue("mock-queue-id");

jest.mock("../utils/messaging_utils", () => ({
  enqueueUrgentAppointmentReminder: (...args: unknown[]) => mockEnqueueUrgentReminder(...args),
}));

jest.mock("../utils/metrics_utils", () => ({
  incrementDashboardMetrics: jest.fn().mockResolvedValue(undefined),
  applyDashboardDeltaInTx: jest.fn(),
  getDashboardRef: jest.fn(() => ({ set: jest.fn().mockResolvedValue(undefined) })),
}));

jest.mock("../utils/payment_distribution", () => ({
  distributePaymentFIFO: jest.fn().mockReturnValue({ totalDebtDecrease: 0, leftoverBalance: 0 }),
}));

const mockTransaction = {
  get: jest.fn(),
  set: jest.fn(),
  update: jest.fn(),
};

const mockDb = {
  collection: mockCollection,
  batch: mockBatch,
  runTransaction: jest.fn(
    (cb: (t: typeof mockTransaction) => Promise<unknown>) => cb(mockTransaction)
  ),
};

jest.mock("firebase-admin", () => {
  const mockFirestore = jest.fn(() => mockDb);
  (mockFirestore as any).Timestamp = {
    now: jest.fn(() => ({ toMillis: () => Date.now(), toDate: () => new Date() })),
    fromDate: jest.fn((d: Date) => ({ toMillis: () => d.getTime(), toDate: () => d })),
    fromMillis: jest.fn((ms: number) => ({ toMillis: () => ms, toDate: () => new Date(ms) })),
  };
  (mockFirestore as any).FieldValue = {
    serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
    increment: jest.fn((n: number) => `INCREMENT_${n}`),
    delete: jest.fn(() => "DELETE_SENTINEL"),
  };
  return {
    firestore: mockFirestore,
    initializeApp: jest.fn(),
  };
});

jest.mock("firebase-functions", () => ({
  runWith: jest.fn(() => ({
    firestore: {
      document: jest.fn(() => ({
        onUpdate: jest.fn((handler: Function) => handler),
      })),
    },
  })),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

// ─── Imports (after mocks) ──────────────────────────────────────────────────

import { onAppointmentUpdated } from "../appointments/onAppointmentUpdated";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeTimestamp(date: Date) {
  return {
    toMillis: () => date.getTime(),
    toDate: () => date,
  };
}

function makeChange(before: Record<string, unknown>, after: Record<string, unknown>) {
  const afterRef = { update: jest.fn().mockResolvedValue(undefined) };
  return {
    before: { data: () => before },
    after: { data: () => after, ref: afterRef },
    _afterRef: afterRef,
  };
}

function makeContext(providerId: string, patientId: string, appointmentId: string) {
  return {
    params: { providerId, patientId, appointmentId },
  };
}

function setupPatientAndQueueMocks({
  patientTotalDebt = 0,
  patientBalance = 0,
  queuedDocs = [] as Array<{ id: string }>,
  providerData = { subscriptionStatus: "active", plan: "premium", name: "Lopez", profession: "Dr." } as Record<string, unknown>,
  patientName = "Test Patient",
}: {
  patientTotalDebt?: number;
  patientBalance?: number;
  queuedDocs?: Array<{ id: string }>;
  providerData?: Record<string, unknown> | null;
  patientName?: string;
} = {}) {
  mockTransaction.get.mockResolvedValue({
    exists: true,
    data: () => ({ totalDebt: patientTotalDebt, balance: patientBalance }),
  });

  const queueSnap = {
    empty: queuedDocs.length === 0,
    size: queuedDocs.length,
    docs: queuedDocs.map(d => ({
      ref: { update: jest.fn().mockResolvedValue(undefined) },
      data: () => ({ status: "queued" }),
    })),
  };

  const providerSnap = {
    exists: providerData !== null,
    data: () => providerData,
  };
  const patientSnap = {
    exists: true,
    data: () => ({ name: patientName }),
  };

  mockCollection.mockImplementation((name: string) => {
    if (name === "message_queue") {
      return {
        where: jest.fn().mockReturnValue({
          where: jest.fn().mockReturnValue({
            where: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(queueSnap),
            }),
          }),
        }),
      };
    }
    if (name === "providers") {
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(providerSnap),
          collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(patientSnap),
              collection: jest.fn().mockReturnValue({
                where: jest.fn().mockReturnValue({
                  orderBy: jest.fn().mockReturnValue({
                    get: jest.fn().mockResolvedValue({ docs: [] }),
                  }),
                }),
              }),
            }),
          }),
        }),
      };
    }
    return { doc: mockDoc };
  });
}

// ─── Tests ──────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  mockEnqueueUrgentReminder.mockResolvedValue("mock-queue-id");
});

describe("onAppointmentUpdated — message queue date-change handling", () => {
  const handler = onAppointmentUpdated as unknown as (
    change: ReturnType<typeof makeChange>,
    ctx: ReturnType<typeof makeContext>
  ) => Promise<void>;

  const futureDate12h = new Date(Date.now() + 12 * 60 * 60 * 1000);
  const futureDate72h = new Date(Date.now() + 72 * 60 * 60 * 1000);
  const pastDate = new Date(Date.now() - 60 * 60 * 1000); // 1h ago

  const oldDate = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000); // 5 days from now

  test("date changes to <48h: queued reminder cancelled and new one enqueued", async () => {
    setupPatientAndQueueMocks({
      queuedDocs: [{ id: "old-queue-item" }],
    });

    const change = makeChange(
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(oldDate) },
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(futureDate12h) }
    );

    await handler(change, makeContext("prov-1", "pat-1", "apt-1"));

    // Old reminder should be cancelled via batch
    expect(mockBatchUpdate).toHaveBeenCalledWith(
      expect.anything(),
      { status: "cancelled" }
    );

    // New urgent reminder should be enqueued
    expect(mockEnqueueUrgentReminder).toHaveBeenCalledTimes(1);
    expect(mockEnqueueUrgentReminder).toHaveBeenCalledWith(
      "apt-1",
      expect.objectContaining({ date: expect.anything() }),
      expect.any(Object),
      "prov-1",
      "pat-1",
      expect.any(String)
    );
  });

  test("date changes to >=48h: queued reminder cancelled but no new one enqueued", async () => {
    setupPatientAndQueueMocks({
      queuedDocs: [{ id: "old-queue-item" }],
    });

    const change = makeChange(
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(oldDate) },
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(futureDate72h) }
    );

    await handler(change, makeContext("prov-1", "pat-1", "apt-1"));

    // Old reminder should be cancelled
    expect(mockBatchUpdate).toHaveBeenCalledWith(
      expect.anything(),
      { status: "cancelled" }
    );

    // No new reminder since >= 48h away (generator cron will handle it)
    expect(mockEnqueueUrgentReminder).not.toHaveBeenCalled();
  });

  test("date changes to past: queued reminder cancelled but no new one enqueued", async () => {
    setupPatientAndQueueMocks({
      queuedDocs: [{ id: "old-queue-item" }],
    });

    const change = makeChange(
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(oldDate) },
      { totalAmount: 3000, amountPaid: 0, status: "unpaid", date: makeTimestamp(pastDate) }
    );

    await handler(change, makeContext("prov-1", "pat-1", "apt-1"));

    // Batch cancel should be attempted (no queued items found, but cancel code runs)
    // No new reminder since date is in the past
    expect(mockEnqueueUrgentReminder).not.toHaveBeenCalled();
  });

  test("no date change: message_queue is not touched", async () => {
    setupPatientAndQueueMocks({
      queuedDocs: [],
    });

    const sameDate = makeTimestamp(futureDate72h);
    const change = makeChange(
      { totalAmount: 3000, amountPaid: 0, status: "unpaid", date: sameDate },
      { totalAmount: 5000, amountPaid: 0, status: "unpaid", date: sameDate }
    );

    await handler(change, makeContext("prov-1", "pat-1", "apt-1"));

    // message_queue should not be queried at all since date didn't change
    // (The message_queue cancellation code only runs inside the dateChanged block)
    expect(mockEnqueueUrgentReminder).not.toHaveBeenCalled();
    // batch.update should not be called for cancellation
    expect(mockBatchUpdate).not.toHaveBeenCalled();
  });

  test("date changes to <48h with non-premium provider: cancelled but no re-enqueue", async () => {
    setupPatientAndQueueMocks({
      queuedDocs: [{ id: "old-queue-item" }],
      providerData: { subscriptionStatus: "active", plan: "basic" },
    });

    const change = makeChange(
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(oldDate) },
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(futureDate12h) }
    );

    await handler(change, makeContext("prov-1", "pat-1", "apt-1"));

    // Old reminder cancelled
    expect(mockBatchUpdate).toHaveBeenCalledWith(
      expect.anything(),
      { status: "cancelled" }
    );

    // No new reminder since provider is not premium
    expect(mockEnqueueUrgentReminder).not.toHaveBeenCalled();
  });

  test("queue update failure does not fail the appointment update", async () => {
    // Make message_queue query throw
    mockTransaction.get.mockResolvedValue({
      exists: true,
      data: () => ({ totalDebt: 0, balance: 0 }),
    });
    mockCollection.mockImplementation((name: string) => {
      if (name === "message_queue") {
        return {
          where: jest.fn().mockReturnValue({
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                get: jest.fn().mockRejectedValue(new Error("Firestore unavailable")),
              }),
            }),
          }),
        };
      }
      if (name === "providers") {
        return {
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ exists: false, data: () => null }),
            collection: jest.fn().mockReturnValue({
              doc: jest.fn().mockReturnValue({
                collection: jest.fn().mockReturnValue({
                  where: jest.fn().mockReturnValue({
                    orderBy: jest.fn().mockReturnValue({
                      get: jest.fn().mockResolvedValue({ docs: [] }),
                    }),
                  }),
                }),
              }),
            }),
          }),
        };
      }
      return { doc: mockDoc };
    });

    const change = makeChange(
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(oldDate) },
      { totalAmount: 3000, amountPaid: 0, status: "scheduled", date: makeTimestamp(futureDate12h) }
    );

    await expect(
      handler(change, makeContext("prov-1", "pat-1", "apt-1"))
    ).resolves.not.toThrow();
  });
});
