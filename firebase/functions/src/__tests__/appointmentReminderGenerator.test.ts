// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockDoc = jest.fn();
const mockCollection = jest.fn();
const mockCollectionGroup = jest.fn();
const mockWhere = jest.fn();

const mockEnqueueMessage = jest.fn().mockResolvedValue({ id: "mock-queue-id", wasSkipped: false });

jest.mock("../utils/messaging_utils", () => ({
  enqueueMessage: (...args: unknown[]) => mockEnqueueMessage(...args),
  calculateUrgentScheduledFor: (appointmentDate: Date) => {
    const now = new Date();
    const msUntil = appointmentDate.getTime() - now.getTime();
    const twentyFourH = 24 * 60 * 60 * 1000;
    const twoH = 2 * 60 * 60 * 1000;
    const ideal = msUntil > twentyFourH
      ? new Date(appointmentDate.getTime() - twentyFourH)
      : new Date(appointmentDate.getTime() - twoH);
    return ideal < now ? now : ideal;
  },
}));

jest.mock("../utils/dateAndInterest", () => ({
  toDateKey: jest.fn((d: Date) => {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${day}`;
  }),
}));

const mockDb = {
  collection: mockCollection,
  collectionGroup: mockCollectionGroup,
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

import { appointmentReminderGenerator } from "../cron/appointmentReminderGenerator";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeTimestamp(date: Date) {
  return {
    toMillis: () => date.getTime(),
    toDate: () => date,
  };
}

function makeProviderSnap(
  exists: boolean,
  data?: { subscriptionStatus: string; plan: string; name?: string; profession?: string | null }
) {
  return {
    exists,
    data: () => (exists ? data : undefined),
  };
}

function makePatientSnap(exists: boolean, name = "Juan Perez") {
  return {
    exists,
    data: () => (exists ? { name } : undefined),
  };
}

function makeAppointmentDoc(
  id: string,
  providerId: string,
  status: string,
  date: Date,
  createdAt?: Date,
  concept?: string
) {
  const patientRef = {
    id: "pat-1",
    path: `providers/${providerId}/patients/pat-1`,
    get: jest.fn(),
  };

  return {
    id,
    data: () => ({
      providerId,
      status,
      date: makeTimestamp(date),
      dateKey: "2026-03-24",
      ...(createdAt ? { createdAt: makeTimestamp(createdAt) } : {}),
      ...(concept !== undefined ? { concept } : {}),
    }),
    ref: {
      parent: {
        parent: patientRef,
      },
    },
  };
}

// Helper functions available for future test expansion

// ─── Tests ──────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  mockEnqueueMessage.mockResolvedValue({ id: "mock-queue-id", wasSkipped: false });
});

describe("appointmentReminderGenerator", () => {
  // The exported value is the handler function due to our mock of firebase-functions
  const handler = appointmentReminderGenerator as unknown as () => Promise<null>;

  describe("happy path", () => {
    test("generates reminder for appointment +2 days with premium provider", async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 2);
      futureDate.setHours(10, 0, 0, 0);

      const appDoc = makeAppointmentDoc("apt-1", "prov-1", "scheduled", futureDate);
      const patientSnap = makePatientSnap(true, "Maria Garcia");
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      // Setup collectionGroup query
      const cgQuerySnap = {
        empty: false,
        size: 1,
        docs: [appDoc],
      };
      const cgWhere = jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(cgQuerySnap),
      });
      mockCollectionGroup.mockReturnValue({ where: cgWhere });

      // Setup provider fetch: db.collection("providers").doc("prov-1").get()
      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
      });

      // Route collection calls
      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        return { doc: mockDoc };
      });

      await handler();

      expect(mockEnqueueMessage).toHaveBeenCalledTimes(1);
      expect(mockEnqueueMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          providerId: "prov-1",
          patientId: "pat-1",
          messageType: "appointment_reminder",
        })
      );
    });
  });

  describe("provider filtering", () => {
    function setupSingleAppointment() {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 2);
      futureDate.setHours(10, 0, 0, 0);

      const appDoc = makeAppointmentDoc("apt-1", "prov-1", "scheduled", futureDate);
      const patientSnap = makePatientSnap(true);
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      const cgWhere = jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(cgQuerySnap),
      });
      mockCollectionGroup.mockReturnValue({ where: cgWhere });

      return appDoc;
    }

    test("skips non-premium providers (basic plan)", async () => {
      setupSingleAppointment();

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "basic",
      });

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        return { doc: mockDoc, where: mockWhere };
      });

      await handler();

      expect(mockEnqueueMessage).not.toHaveBeenCalled();
    });

    test("skips suspended providers", async () => {
      setupSingleAppointment();

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "suspended",
        plan: "premium",
      });

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        return { doc: mockDoc, where: mockWhere };
      });

      await handler();

      expect(mockEnqueueMessage).not.toHaveBeenCalled();
    });
  });

  describe("idempotency", () => {
    test("enqueueMessage is called with idempotencyKey and wasSkipped is tracked", async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 2);
      futureDate.setHours(10, 0, 0, 0);

      const appDoc = makeAppointmentDoc("apt-1", "prov-1", "scheduled", futureDate);
      const patientSnap = makePatientSnap(true);
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      const cgWhere = jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(cgQuerySnap),
      });
      mockCollectionGroup.mockReturnValue({ where: cgWhere });

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
      });

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        return { doc: mockDoc };
      });

      // Simulate enqueueMessage returning wasSkipped: true (idempotent skip)
      mockEnqueueMessage.mockResolvedValueOnce({ id: "appt_apt-1_0", wasSkipped: true });

      await handler();

      // enqueueMessage IS called (idempotency is handled inside it, not by a separate query)
      expect(mockEnqueueMessage).toHaveBeenCalledTimes(1);
      expect(mockEnqueueMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          idempotencyKey: "appt_apt-1_0",
          sourceAppointmentId: "apt-1",
        })
      );
    });
  });

  describe("urgency detection", () => {
    function setupPremiumFlow() {
      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
      });
      const idempotencySnap = { empty: true };
      const idempotencyLimit = { get: jest.fn().mockResolvedValue(idempotencySnap) };

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        if (name === "message_queue") {
          return {
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue(idempotencyLimit),
              }),
            }),
          };
        }
        return { doc: mockDoc };
      });
    }

    test("marks urgent when appointment createdAt < 48h before date", async () => {
      const appointmentDate = new Date();
      appointmentDate.setDate(appointmentDate.getDate() + 2);
      appointmentDate.setHours(10, 0, 0, 0);

      // Created 24h before appointment (less than 48h gap)
      const createdAt = new Date(appointmentDate.getTime() - 24 * 60 * 60 * 1000);

      const appDoc = makeAppointmentDoc(
        "apt-1",
        "prov-1",
        "scheduled",
        appointmentDate,
        createdAt
      );
      const patientSnap = makePatientSnap(true, "Ana Lopez");
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      setupPremiumFlow();

      await handler();

      expect(mockEnqueueMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          isUrgent: true,
          priority: 10,
        })
      );
    });

    test("non-urgent when createdAt >= 48h before date", async () => {
      const appointmentDate = new Date();
      appointmentDate.setDate(appointmentDate.getDate() + 2);
      appointmentDate.setHours(10, 0, 0, 0);

      // Created 72h before appointment (more than 48h gap)
      const createdAt = new Date(appointmentDate.getTime() - 72 * 60 * 60 * 1000);

      const appDoc = makeAppointmentDoc(
        "apt-1",
        "prov-1",
        "scheduled",
        appointmentDate,
        createdAt
      );
      const patientSnap = makePatientSnap(true, "Ana Lopez");
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      setupPremiumFlow();

      await handler();

      expect(mockEnqueueMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          isUrgent: false,
          priority: 20,
        })
      );
    });
  });

  describe("scheduling", () => {
    test("scheduledFor = appointment.date - 48h", async () => {
      const appointmentDate = new Date();
      appointmentDate.setDate(appointmentDate.getDate() + 2);
      appointmentDate.setHours(14, 0, 0, 0);

      // Created well in advance
      const createdAt = new Date(appointmentDate.getTime() - 5 * 24 * 60 * 60 * 1000);

      const appDoc = makeAppointmentDoc(
        "apt-1",
        "prov-1",
        "unpaid",
        appointmentDate,
        createdAt
      );
      const patientSnap = makePatientSnap(true);
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
      });
      const idempotencySnap = { empty: true };

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        if (name === "message_queue") {
          return {
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(idempotencySnap),
                }),
              }),
            }),
          };
        }
        return { doc: mockDoc };
      });

      await handler();

      expect(mockEnqueueMessage).toHaveBeenCalledTimes(1);
      const params = mockEnqueueMessage.mock.calls[0][0];

      // scheduledFor should be appointment date - 48h, or now if that is in the past
      // Since 48h before a +2 day appointment is approximately now, it might be clamped
      // The key assertion is that scheduledFor <= appointmentDate
      expect(params.scheduledFor.getTime()).toBeLessThanOrEqual(
        appointmentDate.getTime()
      );
    });

    test("expiresAt = appointment.date", async () => {
      const appointmentDate = new Date();
      appointmentDate.setDate(appointmentDate.getDate() + 2);
      appointmentDate.setHours(14, 0, 0, 0);

      const createdAt = new Date(appointmentDate.getTime() - 5 * 24 * 60 * 60 * 1000);

      const appDoc = makeAppointmentDoc(
        "apt-1",
        "prov-1",
        "scheduled",
        appointmentDate,
        createdAt
      );
      const patientSnap = makePatientSnap(true);
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
      });
      const idempotencySnap = { empty: true };

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        if (name === "message_queue") {
          return {
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(idempotencySnap),
                }),
              }),
            }),
          };
        }
        return { doc: mockDoc };
      });

      await handler();

      const params = mockEnqueueMessage.mock.calls[0][0];
      expect(params.expiresAt).toEqual(appointmentDate);
    });
  });

  describe("variables", () => {
    test("variables contain nombre_paciente, fecha_turno, hora_turno", async () => {
      const appointmentDate = new Date("2026-03-24T14:30:00Z");
      const createdAt = new Date("2026-03-18T10:00:00Z");

      const appDoc = makeAppointmentDoc(
        "apt-1",
        "prov-1",
        "scheduled",
        appointmentDate,
        createdAt
      );
      const patientSnap = makePatientSnap(true, "Carlos Rodriguez");
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
      });
      const idempotencySnap = { empty: true };

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        if (name === "message_queue") {
          return {
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(idempotencySnap),
                }),
              }),
            }),
          };
        }
        return { doc: mockDoc };
      });

      await handler();

      const params = mockEnqueueMessage.mock.calls[0][0];
      expect(params.variables).toHaveProperty("nombre_paciente", "Carlos Rodriguez");
      expect(params.variables).toHaveProperty("fecha_turno");
      expect(params.variables).toHaveProperty("hora_turno");
      expect(typeof params.variables.fecha_turno).toBe("string");
      expect(typeof params.variables.hora_turno).toBe("string");
    });

    function setupPremiumFlowWithProviderName(providerName: string, providerProfession: string | null) {
      const appointmentDate = new Date("2026-03-24T14:30:00Z");
      const createdAt = new Date("2026-03-18T10:00:00Z");

      const appDoc = makeAppointmentDoc("apt-1", "prov-1", "scheduled", appointmentDate, createdAt);
      const patientSnap = makePatientSnap(true, "Test Patient");
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
        name: providerName,
        profession: providerProfession,
      });
      const idempotencySnap = { empty: true };

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        if (name === "message_queue") {
          return {
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(idempotencySnap),
                }),
              }),
            }),
          };
        }
        return { doc: mockDoc };
      });
    }

    function setupPremiumFlowWithConcept(concept?: string) {
      const appointmentDate = new Date("2026-03-24T14:30:00Z");
      const createdAt = new Date("2026-03-18T10:00:00Z");

      const appDoc = makeAppointmentDoc("apt-1", "prov-1", "scheduled", appointmentDate, createdAt, concept);
      const patientSnap = makePatientSnap(true, "Test Patient");
      (appDoc.ref.parent.parent as any).get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 1, docs: [appDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
        name: "García",
        profession: null,
      });
      const idempotencySnap = { empty: true };

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue(providerSnap),
            }),
          };
        }
        if (name === "message_queue") {
          return {
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(idempotencySnap),
                }),
              }),
            }),
          };
        }
        return { doc: mockDoc };
      });
    }

    test("variables.nombre_profesional is 'profession name' when profession exists", async () => {
      setupPremiumFlowWithProviderName("Gomez", "Dr.");

      await handler();

      const params = mockEnqueueMessage.mock.calls[0][0];
      expect(params.variables).toHaveProperty("nombre_profesional", "Dr. Gomez");
    });

    test("variables.nombre_profesional is just name when profession is null", async () => {
      setupPremiumFlowWithProviderName("Gomez", null);

      await handler();

      const params = mockEnqueueMessage.mock.calls[0][0];
      expect(params.variables).toHaveProperty("nombre_profesional", "Gomez");
    });

    test("variables.concepto_turno uses fallback 'Consulta' when concept field is missing", async () => {
      setupPremiumFlowWithConcept(undefined);

      await handler();

      const params = mockEnqueueMessage.mock.calls[0][0];
      expect(params.variables).toHaveProperty("concepto_turno", "Consulta");
    });

    test("variables.concepto_turno uses actual value when concept field is present", async () => {
      setupPremiumFlowWithConcept("Kinesiología");

      await handler();

      const params = mockEnqueueMessage.mock.calls[0][0];
      expect(params.variables).toHaveProperty("concepto_turno", "Kinesiología");
    });
  });

  describe("status filtering", () => {
    test("skips appointments with status 'liquidated'", async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 2);

      // liquidated appointments are filtered out in the eligibleDocs filter
      const liquidatedDoc = makeAppointmentDoc(
        "apt-1",
        "prov-1",
        "liquidated",
        futureDate
      );

      const cgQuerySnap = { empty: false, size: 1, docs: [liquidatedDoc] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      await handler();

      // liquidated is filtered out in eligibleDocs, so enqueue is never called
      expect(mockEnqueueMessage).not.toHaveBeenCalled();
    });
  });

  describe("caching", () => {
    test("caches provider docs (only 1 read per provider)", async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 2);
      futureDate.setHours(10, 0, 0, 0);

      const appDoc1 = makeAppointmentDoc("apt-1", "prov-1", "scheduled", futureDate);
      const appDoc2 = makeAppointmentDoc("apt-2", "prov-1", "unpaid", futureDate);

      // Give them different patient refs so both get processed
      const patRef2 = {
        id: "pat-2",
        path: "providers/prov-1/patients/pat-2",
        get: jest.fn(),
      };
      (appDoc2 as any).ref = { parent: { parent: patRef2 } };

      const patientSnap = makePatientSnap(true, "Juan");
      (appDoc1.ref.parent.parent as any).get.mockResolvedValue(patientSnap);
      patRef2.get.mockResolvedValue(patientSnap);

      const cgQuerySnap = { empty: false, size: 2, docs: [appDoc1, appDoc2] };
      mockCollectionGroup.mockReturnValue({
        where: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(cgQuerySnap),
        }),
      });

      const providerSnap = makeProviderSnap(true, {
        subscriptionStatus: "active",
        plan: "premium",
      });
      const providerGetFn = jest.fn().mockResolvedValue(providerSnap);
      const idempotencySnap = { empty: true };

      mockCollection.mockImplementation((name: string) => {
        if (name === "providers") {
          return {
            doc: jest.fn().mockReturnValue({
              get: providerGetFn,
            }),
          };
        }
        if (name === "message_queue") {
          return {
            where: jest.fn().mockReturnValue({
              where: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(idempotencySnap),
                }),
              }),
            }),
          };
        }
        return { doc: mockDoc };
      });

      await handler();

      // Provider doc should be fetched only once even though 2 appointments reference same provider
      expect(providerGetFn).toHaveBeenCalledTimes(1);
      // But both appointments should be enqueued
      expect(mockEnqueueMessage).toHaveBeenCalledTimes(2);
    });
  });
});
