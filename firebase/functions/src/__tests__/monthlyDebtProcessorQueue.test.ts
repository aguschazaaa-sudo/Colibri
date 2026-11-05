// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockDoc = jest.fn();
const mockCollection = jest.fn();
const mockCollectionGroup = jest.fn();
const mockBatchUpdate = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue([]);

const mockEnqueueMessage = jest.fn().mockResolvedValue("mock-queue-id");

jest.mock("../utils/messaging_utils", () => ({
  enqueueMessage: (...args: unknown[]) => mockEnqueueMessage(...args),
}));

jest.mock("../utils/dateAndInterest", () => ({
  MONTHLY_INTEREST_RATE: 0.05,
  calculateInterest: jest.fn((amount: number, rate: number) =>
    Math.round(amount * rate)
  ),
}));

jest.mock("../utils/metrics_utils", () => ({
  incrementDashboardMetrics: jest.fn().mockResolvedValue(undefined),
  applyDashboardDeltaInTx: jest.fn(),
  getDashboardRef: jest.fn(() => ({ set: jest.fn().mockResolvedValue(undefined) })),
  resetMonthlyRevenue: jest.fn().mockResolvedValue(undefined),
  saveMonthlySnapshot: jest.fn().mockResolvedValue(undefined),
}));

const mockDb = {
  collection: mockCollection,
  collectionGroup: mockCollectionGroup,
  batch: jest.fn(() => ({
    update: mockBatchUpdate,
    commit: mockBatchCommit,
    set: jest.fn(),
    delete: jest.fn(),
  })),
  getAll: jest.fn(),
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
    increment: jest.fn((n: number) => ({ _type: "increment", value: n })),
  };
  return {
    firestore: mockFirestore,
    initializeApp: jest.fn(),
  };
});

jest.mock("firebase-functions", () => ({
  runWith: jest.fn(() => ({
    pubsub: {
      schedule: jest.fn(() => ({
        timeZone: jest.fn(() => ({
          onRun: jest.fn((handler: Function) => handler),
        })),
      })),
    },
  })),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

// ─── Imports (after mocks) ──────────────────────────────────────────────────

import { monthlyDebtProcessor } from "../cron/monthlyDebtProcessor";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeTimestamp(date: Date) {
  return {
    toMillis: () => date.getTime(),
    toDate: () => date,
  };
}

function makeProviderDoc(id: string, status = "active", plan = "premium") {
  return {
    id,
    data: () => ({ subscriptionStatus: status, plan }),
    ref: { id },
  };
}

function makeAppointmentDoc(
  id: string,
  providerId: string,
  totalAmount: number,
  amountPaid: number,
  date: Date
) {
  const patientRef = {
    id: `patient-of-${id}`,
    path: `providers/${providerId}/patients/patient-of-${id}`,
  };
  return {
    id,
    data: () => ({
      providerId,
      status: "unpaid",
      totalAmount,
      amountPaid,
      date: makeTimestamp(date),
    }),
    ref: {
      parent: { parent: patientRef },
      update: jest.fn(),
    },
  };
}

function makePatientDocSnapshot(
  path: string,
  providerId: string,
  name: string,
  totalDebt: number
) {
  return {
    exists: true,
    id: path.split("/").pop()!,
    ref: { path, id: path.split("/").pop()! },
    data: () => ({ providerId, name, totalDebt }),
  };
}

// ─── Tests ──────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
});

// ─── Task 7.4 — post-cleanup: monthlyDebtProcessor must NOT enqueue messages ─

describe("monthlyDebtProcessor — post-cleanup: no WhatsApp enqueuing", () => {
  const handler = monthlyDebtProcessor as unknown as () => Promise<null>;

  test("monthlyDebtProcessor does NOT call enqueueMessage after cleanup (task 4.1)", async () => {
    // Scenario: active premium provider with overdue debt — should process interest
    // but NOT call enqueueMessage (that responsibility moved to monthlyDebtNotifier)
    const pastDate = new Date();
    pastDate.setMonth(pastDate.getMonth() - 2); // 2 months ago

    const providerDocs = [makeProviderDoc("prov-post-cleanup")];
    const appointmentDoc = makeAppointmentDoc(
      "apt-post",
      "prov-post-cleanup",
      8000,
      0,
      pastDate
    );

    const providersSnap = { empty: false, size: 1, docs: providerDocs };
    const unpaidSnap = { empty: false, size: 1, docs: [appointmentDoc] };

    const cgWhereInner = jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue(unpaidSnap),
    });
    const cgWhere = jest.fn().mockReturnValue({ where: cgWhereInner });
    mockCollectionGroup.mockReturnValue({ where: cgWhere });

    const patientSnap = makePatientDocSnapshot(
      "providers/prov-post-cleanup/patients/patient-of-apt-post",
      "prov-post-cleanup",
      "Luis Rodríguez",
      8000
    );
    mockDb.getAll.mockResolvedValue([patientSnap]);

    const providersQuery = {
      where: jest.fn(),
      get: jest.fn().mockResolvedValue(providersSnap),
    };
    providersQuery.where.mockReturnValue(providersQuery);

    mockCollection.mockImplementation((name: string) => {
      if (name === "providers") {
        return {
          where: jest.fn().mockReturnValue(providersQuery),
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(providerDocs[0]),
          }),
        };
      }
      return { doc: mockDoc, add: jest.fn() };
    });

    await handler();

    // After cleanup (task 4.1), enqueueMessage must NOT be called by monthlyDebtProcessor
    expect(mockEnqueueMessage).not.toHaveBeenCalled();
  });
});

// Note: The old "queueWhatsAppReminder" describe block was removed.
// WhatsApp payment reminders are now handled by monthlyDebtNotifier (task 4.1 cleanup).
// Tests for that behavior live in monthlyDebtNotifier.test.ts.
