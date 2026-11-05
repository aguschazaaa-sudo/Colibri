// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockDoc = jest.fn();
const mockCollection = jest.fn();

const mockEnqueueMessage = jest.fn().mockResolvedValue("mock-queue-id");

jest.mock("../utils/messaging_utils", () => ({
  enqueueMessage: (...args: unknown[]) => mockEnqueueMessage(...args),
}));

const mockDb = {
  collection: mockCollection,
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
  };
  return {
    firestore: mockFirestore,
    initializeApp: jest.fn(),
  };
});

jest.mock("firebase-functions", () => ({
  runWith: jest.fn(() => ({
    https: {
      onCall: jest.fn((handler: Function) => handler),
    },
  })),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
  https: {
    HttpsError: class HttpsError extends Error {
      constructor(public code: string, msg: string) {
        super(msg);
        this.name = "HttpsError";
      }
    },
  },
}));

// ─── Imports (after mocks) ──────────────────────────────────────────────────

import { triggerManualReminders } from "../workers/triggerManualReminders";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makePatientDoc(id: string, name: string, totalDebt: number) {
  return {
    id,
    data: () => ({ name, totalDebt }),
  };
}

function makeAuthContext(uid: string) {
  return {
    auth: { uid },
  };
}

function setupProviderAndPatients(
  providerData: Record<string, unknown> | null,
  patients: ReturnType<typeof makePatientDoc>[]
) {
  const providerSnap = {
    exists: providerData !== null,
    data: () => providerData,
  };

  const patientsSnap = {
    empty: patients.length === 0,
    docs: patients,
  };

  mockCollection.mockImplementation((name: string) => {
    if (name === "providers") {
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(providerSnap),
          collection: jest.fn().mockReturnValue({
            where: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(patientsSnap),
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
});

describe("triggerManualReminders — queue routing", () => {
  const handler = triggerManualReminders as unknown as (
    data: unknown,
    context: ReturnType<typeof makeAuthContext>
  ) => Promise<{ queued: number; message: string }>;

  test("writes to message_queue via enqueueMessage, NOT to communications", async () => {
    const patients = [
      makePatientDoc("pat-1", "Juan Perez", 5000),
      makePatientDoc("pat-2", "Maria Lopez", 3000),
    ];

    setupProviderAndPatients(
      { subscriptionStatus: "active" },
      patients
    );

    await handler({}, makeAuthContext("prov-1"));

    expect(mockEnqueueMessage).toHaveBeenCalledTimes(2);

    // Verify first call uses enqueueMessage (not direct Firestore write)
    expect(mockEnqueueMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        providerId: "prov-1",
        patientId: "pat-1",
        patientName: "Juan Perez",
        messageType: "payment_reminder",
      })
    );

    expect(mockEnqueueMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        providerId: "prov-1",
        patientId: "pat-2",
        patientName: "Maria Lopez",
        messageType: "payment_reminder",
      })
    );
  });

  test("priority = 25", async () => {
    setupProviderAndPatients(
      { subscriptionStatus: "active" },
      [makePatientDoc("pat-1", "Juan", 1000)]
    );

    await handler({}, makeAuthContext("prov-1"));

    expect(mockEnqueueMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        priority: 25,
      })
    );
  });

  test("returns count of enqueued messages", async () => {
    const patients = [
      makePatientDoc("pat-1", "Juan", 5000),
      makePatientDoc("pat-2", "Maria", 3000),
      makePatientDoc("pat-3", "Carlos", 7000),
    ];

    setupProviderAndPatients(
      { subscriptionStatus: "active" },
      patients
    );

    const result = await handler({}, makeAuthContext("prov-1"));

    expect(result.queued).toBe(3);
    expect(result.message).toContain("3");
  });

  test("throws unauthenticated when no auth context", async () => {
    const noAuthContext = { auth: undefined } as any;

    await expect(handler({}, noAuthContext)).rejects.toThrow();
  });

  test("returns queued=0 when subscription is not active", async () => {
    setupProviderAndPatients(
      { subscriptionStatus: "suspended" },
      [makePatientDoc("pat-1", "Juan", 5000)]
    );

    const result = await handler({}, makeAuthContext("prov-1"));

    expect(result.queued).toBe(0);
    expect(mockEnqueueMessage).not.toHaveBeenCalled();
  });

  test("returns queued=0 when no patients have debt", async () => {
    setupProviderAndPatients(
      { subscriptionStatus: "active" },
      [] // empty patients list (query filters totalDebt > 0)
    );

    const result = await handler({}, makeAuthContext("prov-1"));

    expect(result.queued).toBe(0);
    expect(mockEnqueueMessage).not.toHaveBeenCalled();
  });

  test("variables contain nombre_paciente and monto_total", async () => {
    setupProviderAndPatients(
      { subscriptionStatus: "active" },
      [makePatientDoc("pat-1", "Juan Perez", 12500)]
    );

    await handler({}, makeAuthContext("prov-1"));

    const params = mockEnqueueMessage.mock.calls[0][0];
    expect(params.variables.nombre_paciente).toBe("Juan Perez");
    expect(params.variables.monto_total).toBe(12500);
  });
});
