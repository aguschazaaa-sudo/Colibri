// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockDoc = jest.fn();
const mockCollection = jest.fn();

const mockEnqueueMessage = jest.fn().mockResolvedValue("mock-queue-id");

jest.mock("../utils/messaging_utils", () => ({
  enqueueMessage: (...args: unknown[]) => mockEnqueueMessage(...args),
  formatCurrency: jest.fn((amount: number) => `$${amount.toLocaleString("es-AR")}`),
  formatDebtDetail: jest.fn(() => ({
    detalleOrigen: "$5.000 del 15/03",
    fechas: "- 15/03/2026: $5.000",
  })),
}));

const mockDb = {
  collection: mockCollection,
  batch: jest.fn(() => ({
    update: jest.fn(),
    commit: jest.fn().mockResolvedValue([]),
    set: jest.fn(),
    delete: jest.fn(),
  })),
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

import * as functions from "firebase-functions";
import { monthlyDebtNotifier } from "../cron/monthlyDebtNotifier";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeTimestamp(date: Date) {
  return {
    toMillis: () => date.getTime(),
    toDate: () => date,
  };
}

function makeProviderDoc(
  id: string,
  status = "active",
  plan = "basic",
  name = "Centro Médico",
  profession = "Lic."
) {
  return {
    id,
    data: () => ({ subscriptionStatus: status, plan, name, profession }),
  };
}

function makePatientDoc(
  id: string,
  name: string,
  totalDebt: number
) {
  return {
    id,
    data: () => ({ name, totalDebt }),
  };
}

function makeAppointmentDoc(
  id: string,
  date: Date,
  totalAmount: number,
  amountPaid = 0
) {
  return {
    id,
    data: () => ({
      status: "unpaid",
      date: makeTimestamp(date),
      totalAmount,
      amountPaid,
    }),
  };
}

/**
 * Builds a minimal Firestore mock for the notifier's query chain:
 * 1. providers query (3 parallel: basic, premium, trial) → providerDocs
 * 2. patients subcollection query per provider → patientDocs
 * 3. appointments subcollection query per patient → appointmentDocs
 */
function setupFirestoreMock(
  providerDocs: ReturnType<typeof makeProviderDoc>[],
  patientDocs: ReturnType<typeof makePatientDoc>[],
  appointmentDocs: ReturnType<typeof makeAppointmentDoc>[]
) {
  const aptsSnap = { docs: appointmentDocs, empty: appointmentDocs.length === 0 };
  const aptsOrderBy = jest.fn().mockReturnValue({ get: jest.fn().mockResolvedValue(aptsSnap) });
  const aptsWhereStatus = jest.fn().mockReturnValue({ orderBy: aptsOrderBy });

  const patientsSnap = { docs: patientDocs, empty: patientDocs.length === 0 };
  const patientsWhere = jest.fn().mockReturnValue({ get: jest.fn().mockResolvedValue(patientsSnap) });

  // per-patient doc ref (to access subcollection "appointments")
  const aptsSubcollection = jest.fn().mockReturnValue({ where: aptsWhereStatus });
  const patientDocRef = jest.fn().mockReturnValue({ collection: aptsSubcollection });

  // provider patients collection → where().get() returns patientDocs
  // provider doc ref → .collection("patients").doc(id).collection("appointments")
  const patientSubcollection = jest.fn().mockImplementation((name: string) => {
    if (name === "appointments") return { where: aptsWhereStatus };
    // "patients" — returns a collection with where AND .doc()
    return {
      where: patientsWhere,
      doc: patientDocRef,
    };
  });

  const providerDocRef = jest.fn().mockReturnValue({ collection: patientSubcollection });

  // The notifier does 3 parallel queries: basic, premium, trial.
  // Return providerDocs only for "basic" plan, empty for others to avoid
  // processing the same provider 3 times in tests.
  const providersSnap = { docs: providerDocs, empty: providerDocs.length === 0 };
  const emptySnap = { docs: [], empty: true };

  const providersWhere2 = jest.fn().mockImplementation((_field: string, _op: string, value: string) => {
    // Return results only for "basic" plan to avoid duplicates
    const snap = value === "basic" ? providersSnap : emptySnap;
    return { get: jest.fn().mockResolvedValue(snap) };
  });
  const providersWhere1 = jest.fn().mockReturnValue({ where: providersWhere2 });

  mockCollection.mockImplementation((name: string) => {
    if (name === "providers") {
      return {
        where: providersWhere1,
        doc: providerDocRef,
      };
    }
    return { doc: mockDoc, add: jest.fn() };
  });
}

// ─── Tests ──────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
});

describe("monthlyDebtNotifier", () => {
  const handler = monthlyDebtNotifier as unknown as () => Promise<null>;

  // Task 7.3.1 — active provider with patient totalDebt > 0
  test("active provider with patient totalDebt > 0: enqueues payment_reminder", async () => {
    const providers = [makeProviderDoc("prov-1", "active", "basic")];
    const patients = [makePatientDoc("pat-1", "Ana García", 5000)];
    const appointments = [
      makeAppointmentDoc("apt-1", new Date("2026-03-15"), 5000, 0),
    ];
    setupFirestoreMock(providers, patients, appointments);

    await handler();

    expect(mockEnqueueMessage).toHaveBeenCalledTimes(1);
    expect(mockEnqueueMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        providerId: "prov-1",
        patientId: "pat-1",
        messageType: "payment_reminder",
        priority: 30,
        isUrgent: false,
      })
    );
  });

  // Task 7.3.2 — suspended provider: skip
  test("provider with subscriptionStatus != active: does NOT enqueue", async () => {
    // No active providers returned (empty snap)
    setupFirestoreMock([], [], []);

    await handler();

    expect(mockEnqueueMessage).not.toHaveBeenCalled();
  });

  // Task 7.3.3 — patient with totalDebt = 0: skip
  test("patient with totalDebt = 0: does NOT enqueue", async () => {
    const providers = [makeProviderDoc("prov-1", "active", "premium")];
    const patients = [makePatientDoc("pat-zero", "Carlos Mendez", 0)];
    setupFirestoreMock(providers, patients, []);

    await handler();

    expect(mockEnqueueMessage).not.toHaveBeenCalled();
  });

  // Task 7.3.4 — discrepancy between totalDebt and sum of appointments: logs warning, still enqueues
  test("discrepancy between totalDebt and appointments sum: logs warning but still enqueues", async () => {
    const providers = [makeProviderDoc("prov-1", "active", "basic")];
    // Patient reports totalDebt=10000 but appointment only sums to 5000
    const patients = [makePatientDoc("pat-disc", "Ana García", 10000)];
    const appointments = [
      makeAppointmentDoc("apt-disc", new Date("2026-03-15"), 5000, 0),
    ];
    setupFirestoreMock(providers, patients, appointments);

    await handler();

    expect(functions.logger.warn).toHaveBeenCalled();
    // Still enqueues despite discrepancy
    expect(mockEnqueueMessage).toHaveBeenCalledTimes(1);
  });

  // Task 7.3.5 — >7 unpaid appointments: fechas variable is truncated
  test(">7 unpaid appointments: enqueues with truncated fechas variable", async () => {
    const { formatDebtDetail } = require("../utils/messaging_utils");
    // Override mock to return truncated output (simulates the real implementation)
    (formatDebtDetail as jest.Mock).mockReturnValueOnce({
      detalleOrigen: "la suma de 10 turnos pendientes",
      fechas: "- 10/03/2026: $1.000\n- 09/03/2026: $1.000\n- 08/03/2026: $1.000\n- 07/03/2026: $1.000\n- 06/03/2026: $1.000\n- 05/03/2026: $1.000\n- 04/03/2026: $1.000\n... y 3 turnos anteriores",
    });

    const providers = [makeProviderDoc("prov-1", "active", "basic")];
    const patients = [makePatientDoc("pat-many", "Ana García", 10000)];
    const appointments = Array.from({ length: 10 }, (_, i) =>
      makeAppointmentDoc(`apt-${i}`, new Date(2026, 2, i + 1), 1000, 0)
    );
    setupFirestoreMock(providers, patients, appointments);

    await handler();

    const params = mockEnqueueMessage.mock.calls[0][0];
    expect(params.variables.fechas).toContain("... y 3 turnos anteriores");
    expect(params.variables.detalle_origen).toBe("la suma de 10 turnos pendientes");
  });

  // expiresAt should be scheduledFor + 10 days
  test("expiresAt is approximately now + 10 days", async () => {
    const providers = [makeProviderDoc("prov-1", "active", "basic")];
    const patients = [makePatientDoc("pat-1", "Ana García", 5000)];
    const appointments = [
      makeAppointmentDoc("apt-1", new Date("2026-03-15"), 5000, 0),
    ];
    setupFirestoreMock(providers, patients, appointments);

    const beforeCall = Date.now();
    await handler();
    const afterCall = Date.now();

    const params = mockEnqueueMessage.mock.calls[0][0];
    const expiresAtMs = params.expiresAt.getTime();
    const tenDaysMs = 10 * 24 * 60 * 60 * 1000;

    expect(expiresAtMs).toBeGreaterThanOrEqual(beforeCall + tenDaysMs - 5000);
    expect(expiresAtMs).toBeLessThanOrEqual(afterCall + tenDaysMs + 5000);
  });
});
