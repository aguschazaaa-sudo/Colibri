// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockDoc = jest.fn();
const mockCollection = jest.fn();
const mockBatchUpdate = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  update: mockBatchUpdate,
  commit: mockBatchCommit,
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
    now: jest.fn(() => ({
      toMillis: () => Date.now(),
      toDate: () => new Date(),
    })),
    fromDate: jest.fn((d: Date) => ({
      toMillis: () => d.getTime(),
      toDate: () => d,
    })),
    fromMillis: jest.fn((ms: number) => ({
      toMillis: () => ms,
      toDate: () => new Date(ms),
    })),
  };
  (mockFirestore as any).FieldValue = {
    serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
    increment: jest.fn((n: number) => `INCREMENT_${n}`),
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
        onDelete: jest.fn((handler: Function) => handler),
      })),
    },
  })),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

// ─── Imports (after mocks) ──────────────────────────────────────────────────

import { onAppointmentDeleted } from "../appointments/onAppointmentDeleted";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeSnapshot(data: Record<string, unknown>) {
  return {
    data: () => data,
    ref: { update: jest.fn() },
  };
}

function makeContext(providerId: string, patientId: string, appointmentId: string) {
  return {
    params: { providerId, patientId, appointmentId },
  };
}

function setupPatientDoc(totalDebt = 0, balance = 0) {
  mockTransaction.get.mockResolvedValue({
    exists: true,
    data: () => ({ totalDebt, balance }),
  });
}

/**
 * Sets up the message_queue query mock for cancellation.
 * @param queueDocs - docs returned by the query (sourceAppointmentId + status==queued)
 */
function setupMessageQueueCancellation(queueDocs: Array<{id: string; refUpdate: jest.Mock}>) {
  const queueSnap = {
    empty: queueDocs.length === 0,
    size: queueDocs.length,
    docs: queueDocs.map(d => ({
      ref: { update: d.refUpdate },
      data: () => ({ status: "queued" }),
    })),
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
    // providers collection for patient data
    return {
      doc: jest.fn().mockReturnValue({
        collection: jest.fn().mockReturnValue({
          doc: mockDoc,
          where: jest.fn().mockReturnValue({
            orderBy: jest.fn().mockReturnValue({
              get: jest.fn(), // not used in deleted trigger normally
            }),
          }),
        }),
        update: jest.fn(),
      }),
    };
  });
}

// ─── Tests ──────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
});

describe("onAppointmentDeleted — message queue cancellation", () => {
  const handler = onAppointmentDeleted as unknown as (
    snap: ReturnType<typeof makeSnapshot>,
    ctx: ReturnType<typeof makeContext>
  ) => Promise<void>;

  test("queued reminder is cancelled when appointment is deleted", async () => {
    const queueItemRefUpdate = jest.fn().mockResolvedValue(undefined);

    setupPatientDoc(5000, 0);
    setupMessageQueueCancellation([{ id: "queue-item-1", refUpdate: queueItemRefUpdate }]);

    const snap = makeSnapshot({
      totalAmount: 5000,
      amountPaid: 0,
      status: "unpaid",
    });

    await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

    expect(mockBatchUpdate).toHaveBeenCalledWith(
      expect.anything(),
      { status: "cancelled" }
    );
    expect(mockBatchCommit).toHaveBeenCalled();
  });

  test("processing reminder is not touched when appointment is deleted (only queued are cancelled)", async () => {
    // The query explicitly filters status == "queued", so processing items
    // won't be in queueDocs
    setupPatientDoc(5000, 0);
    setupMessageQueueCancellation([]); // no queued items returned

    const snap = makeSnapshot({
      totalAmount: 5000,
      amountPaid: 0,
      status: "unpaid",
    });

    await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

    // batch.update should NOT be called since no queued items
    expect(mockBatchUpdate).not.toHaveBeenCalled();
  });

  test("no error when appointment has no queued reminders", async () => {
    setupPatientDoc(0, 0);
    setupMessageQueueCancellation([]); // empty queue

    const snap = makeSnapshot({
      totalAmount: 1000,
      amountPaid: 0,
      status: "unpaid",
    });

    await expect(
      handler(snap, makeContext("prov-1", "pat-1", "apt-1"))
    ).resolves.not.toThrow();

    expect(mockBatchUpdate).not.toHaveBeenCalled();
  });

  test("cancellation failure does not fail the appointment deletion", async () => {
    setupPatientDoc(5000, 0);

    // Make the message_queue query throw
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
      return {
        doc: jest.fn().mockReturnValue({
          collection: jest.fn().mockReturnValue({
            doc: mockDoc,
          }),
          update: jest.fn(),
        }),
      };
    });

    const snap = makeSnapshot({
      totalAmount: 5000,
      amountPaid: 0,
      status: "unpaid",
    });

    // Should NOT throw even though cancellation failed
    await expect(
      handler(snap, makeContext("prov-1", "pat-1", "apt-1"))
    ).resolves.not.toThrow();
  });

  test("multiple queued reminders are all cancelled in one batch", async () => {
    const refUpdate1 = jest.fn().mockResolvedValue(undefined);
    const refUpdate2 = jest.fn().mockResolvedValue(undefined);

    setupPatientDoc(5000, 0);
    setupMessageQueueCancellation([
      { id: "queue-item-1", refUpdate: refUpdate1 },
      { id: "queue-item-2", refUpdate: refUpdate2 },
    ]);

    const snap = makeSnapshot({
      totalAmount: 5000,
      amountPaid: 0,
      status: "unpaid",
    });

    await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

    expect(mockBatchUpdate).toHaveBeenCalledTimes(2);
    expect(mockBatchCommit).toHaveBeenCalledTimes(1);
  });
});
