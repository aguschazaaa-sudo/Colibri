// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockDoc = jest.fn();
const mockCollection = jest.fn();

const mockEnqueueMessage = jest.fn().mockResolvedValue("mock-queue-id");

jest.mock("../utils/messaging_utils", () => ({
  enqueueUrgentAppointmentReminder: (...args: unknown[]) => mockEnqueueMessage(...args),
}));

jest.mock("../utils/metrics_utils", () => ({
  incrementDashboardMetrics: jest.fn().mockResolvedValue(undefined),
  applyDashboardDeltaInTx: jest.fn(),
  getDashboardRef: jest.fn(() => ({ set: jest.fn().mockResolvedValue(undefined) })),
}));

const mockTransaction = {
  get: jest.fn(),
  set: jest.fn(),
  update: jest.fn(),
};

const mockDb = {
  collection: mockCollection,
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
        onCreate: jest.fn((handler: Function) => handler),
      })),
    },
  })),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
  https: {
    HttpsError: class extends Error {
      constructor(public code: string, msg: string) {
        super(msg);
      }
    },
  },
}));

// ─── Imports (after mocks) ──────────────────────────────────────────────────

import { onAppointmentCreated } from "../appointments/onAppointmentCreated";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeTimestamp(date: Date) {
  return {
    toMillis: () => date.getTime(),
    toDate: () => date,
  };
}

function makeSnapshot(data: Record<string, unknown>) {
  return {
    data: () => data,
    ref: {
      update: jest.fn(),
    },
  };
}

function makeContext(providerId: string, patientId: string, appointmentId: string) {
  return {
    params: { providerId, patientId, appointmentId },
  };
}

function setupPatientDoc(balance = 0, totalDebt = 0) {
  mockTransaction.get.mockResolvedValue({
    exists: true,
    data: () => ({ balance, totalDebt }),
  });
}

function setupProviderAndPatientForQueue(
  providerData: { subscriptionStatus: string; plan: string; name?: string; profession?: string } | null,
  patientName = "Test Patient"
) {
  const providerSnap = {
    exists: providerData !== null,
    data: () => providerData,
  };
  const patientSnap = {
    exists: true,
    data: () => ({ name: patientName }),
  };

  mockCollection.mockImplementation((name: string) => {
    if (name === "providers") {
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(providerSnap),
          collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({
              collection: jest.fn().mockReturnValue({
                doc: jest.fn(),
              }),
              get: jest.fn().mockResolvedValue(patientSnap),
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
  mockEnqueueMessage.mockResolvedValue("mock-queue-id");
});

describe("onAppointmentCreated — fast-path queue", () => {
  // The exported value is the handler function due to our mock
  const handler = onAppointmentCreated as unknown as (
    snap: ReturnType<typeof makeSnapshot>,
    ctx: ReturnType<typeof makeContext>
  ) => Promise<void>;

  describe("urgent reminder enqueue", () => {
    test("appointment <48h + premium provider enqueues urgent reminder", async () => {
      // Appointment 12 hours from now (less than 48h, in the past for the trigger
      // but the fast-path checks hoursUntilAppointment > 0 && < 48)
      const appointmentDate = new Date(Date.now() + 12 * 60 * 60 * 1000);

      const snap = makeSnapshot({
        totalAmount: 5000,
        date: makeTimestamp(appointmentDate),
      });

      // Patient has no balance, so full debt path
      setupPatientDoc(0, 0);

      setupProviderAndPatientForQueue(
        { subscriptionStatus: "active", plan: "premium" },
        "Maria Garcia"
      );

      await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

      expect(mockEnqueueMessage).toHaveBeenCalledTimes(1);
      // enqueueUrgentAppointmentReminder(appointmentId, appointmentData, providerData, providerId, patientId, patientName)
      expect(mockEnqueueMessage).toHaveBeenCalledWith(
        "apt-1",                          // appointmentId
        expect.objectContaining({date: expect.anything()}), // appointmentData
        expect.any(Object),               // providerData
        "prov-1",                         // providerId
        "pat-1",                          // patientId
        "Maria Garcia"                    // patientName
      );
    });

    test("appointment >48h + premium provider does NOT enqueue", async () => {
      // Appointment 72 hours from now (more than 48h)
      const appointmentDate = new Date(Date.now() + 72 * 60 * 60 * 1000);

      const snap = makeSnapshot({
        totalAmount: 5000,
        date: makeTimestamp(appointmentDate),
      });

      // Future appointment: the function returns early after setting status=scheduled
      // so enqueue is never reached
      await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

      expect(mockEnqueueMessage).not.toHaveBeenCalled();
    });

    test("appointment <48h + basic provider does NOT enqueue", async () => {
      const appointmentDate = new Date(Date.now() + 12 * 60 * 60 * 1000);

      const snap = makeSnapshot({
        totalAmount: 5000,
        date: makeTimestamp(appointmentDate),
      });

      setupPatientDoc(0, 0);

      setupProviderAndPatientForQueue({
        subscriptionStatus: "active",
        plan: "basic",
      });

      await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

      expect(mockEnqueueMessage).not.toHaveBeenCalled();
    });
  });

  describe("queue entry properties", () => {
    test("enqueueUrgentAppointmentReminder is called with correct appointmentId and providerId", async () => {
      const appointmentDate = new Date(Date.now() + 6 * 60 * 60 * 1000);

      const snap = makeSnapshot({
        totalAmount: 3000,
        date: makeTimestamp(appointmentDate),
      });

      setupPatientDoc(0, 0);
      setupProviderAndPatientForQueue({
        subscriptionStatus: "active",
        plan: "premium",
        name: "Lopez",
        profession: "Dr.",
      });

      await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

      // enqueueUrgentAppointmentReminder(appointmentId, appointmentData, providerData, providerId, patientId, patientName)
      const [appointmentId, appointmentData, providerData, providerId, patientId] =
        mockEnqueueMessage.mock.calls[0];

      expect(appointmentId).toBe("apt-1");
      expect(providerId).toBe("prov-1");
      expect(patientId).toBe("pat-1");
      expect(appointmentData).toHaveProperty("date");
      expect(providerData).toHaveProperty("name", "Lopez");
      expect(providerData).toHaveProperty("profession", "Dr.");
    });

    test("appointmentData includes concept field when present", async () => {
      const appointmentDate = new Date(Date.now() + 6 * 60 * 60 * 1000);

      const snap = makeSnapshot({
        totalAmount: 3000,
        date: makeTimestamp(appointmentDate),
        concept: "Kinesiología",
      });

      setupPatientDoc(0, 0);
      setupProviderAndPatientForQueue({
        subscriptionStatus: "active",
        plan: "premium",
      });

      await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

      const [, appointmentData] = mockEnqueueMessage.mock.calls[0];
      expect(appointmentData).toHaveProperty("concept", "Kinesiología");
    });

    test("appointmentData concept is undefined when not present (defaults to Consulta in util)", async () => {
      const appointmentDate = new Date(Date.now() + 6 * 60 * 60 * 1000);

      const snap = makeSnapshot({
        totalAmount: 3000,
        date: makeTimestamp(appointmentDate),
        // no concept field
      });

      setupPatientDoc(0, 0);
      setupProviderAndPatientForQueue({
        subscriptionStatus: "active",
        plan: "premium",
      });

      await handler(snap, makeContext("prov-1", "pat-1", "apt-1"));

      const [, appointmentData] = mockEnqueueMessage.mock.calls[0];
      // concept is undefined — enqueueUrgentAppointmentReminder handles the default
      expect(appointmentData.concept).toBeUndefined();
    });
  });

  describe("non-fatal queue failure", () => {
    test("failure to queue does not fail the appointment creation", async () => {
      const appointmentDate = new Date(Date.now() + 6 * 60 * 60 * 1000);

      const snap = makeSnapshot({
        totalAmount: 3000,
        date: makeTimestamp(appointmentDate),
      });

      setupPatientDoc(0, 0);
      setupProviderAndPatientForQueue({
        subscriptionStatus: "active",
        plan: "premium",
      });

      // Make enqueueMessage throw
      mockEnqueueMessage.mockRejectedValueOnce(new Error("Queue service unavailable"));

      // Should NOT throw even though enqueue failed
      await expect(
        handler(snap, makeContext("prov-1", "pat-1", "apt-1"))
      ).resolves.not.toThrow();
    });
  });
});
