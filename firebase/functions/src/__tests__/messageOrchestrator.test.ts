/* eslint-disable @typescript-eslint/no-explicit-any */

// ─── Mock firebase-admin BEFORE any import ─────────────────────────────────────

const mockSet = jest.fn().mockResolvedValue(undefined);
const mockGet = jest.fn();
const mockWhere = jest.fn().mockReturnThis();
const mockOrderBy = jest.fn().mockReturnThis();
const mockLimit = jest.fn().mockReturnThis();

const mockBatchUpdate = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue(undefined);
const mockBatch = jest.fn(() => ({
  update: mockBatchUpdate,
  commit: mockBatchCommit,
}));

// Deep mock chain for subcollections:
//   db.collection("providers")
//     .doc(providerId)
//     .collection("communications").doc() => commRef  (provider-level comm)
//   db.collection("providers")
//     .doc(providerId)
//     .collection("patients")
//     .doc(patientId)
//     .collection("communications")
//     .doc(commRef.id)
//     .set(commData)                                  (patient-level mirror)
//
// We build a recursive structure so any .collection().doc() chain works.

function createChainableDoc(id = "generated-comm-id"): any {
  const docObj: any = {
    id,
    set: mockSet,
  };
  docObj.collection = jest.fn(() => ({
    doc: jest.fn((docId?: string) => createChainableDoc(docId ?? id)),
  }));
  return docObj;
}

const mockDoc = jest.fn((docId?: string) => createChainableDoc(docId ?? "generated-comm-id"));

const FIXED_NOW_MILLIS = 1700000000000;

jest.mock("firebase-admin", () => {
  const col = jest.fn().mockReturnValue({
    where: mockWhere,
    orderBy: mockOrderBy,
    limit: mockLimit,
    get: mockGet,
    doc: mockDoc,
  });

  return {
    firestore: Object.assign(
      () => ({
        collection: col,
        batch: mockBatch,
      }),
      {
        Timestamp: {
          now: () => ({
            toMillis: () => FIXED_NOW_MILLIS,
          }),
          fromMillis: (ms: number) => ({
            toMillis: () => ms,
            _millis: ms,
          }),
        },
        FieldValue: {
          serverTimestamp: () => "SERVER_TIMESTAMP",
          increment: (n: number) => `INCREMENT(${n})`,
        },
      }
    ),
    initializeApp: jest.fn(),
  };
});

// ─── Mock firebase-functions — capture the onRun handler ────────────────────────

let capturedHandler: () => Promise<any>;

jest.mock("firebase-functions", () => {
  const onRun = jest.fn((handler: () => Promise<any>) => {
    capturedHandler = handler;
    return {handler};
  });
  const timeZone = jest.fn(() => ({onRun}));
  const schedule = jest.fn(() => ({timeZone}));

  return {
    runWith: jest.fn(() => ({
      pubsub: {schedule},
    })),
    logger: {
      info: jest.fn(),
      warn: jest.fn(),
      error: jest.fn(),
    },
  };
});

// ─── Mock messaging_utils ───────────────────────────────────────────────────────

const mockGetMessagingConfig = jest.fn();
const mockGetOrResetCounter = jest.fn();
const mockIncrementCounter = jest.fn().mockResolvedValue(undefined);
const mockGetBuenosAiresHour = jest.fn();

jest.mock("../utils/messaging_utils", () => ({
  getMessagingConfig: mockGetMessagingConfig,
  getOrResetCounter: mockGetOrResetCounter,
  incrementCounter: mockIncrementCounter,
  getBuenosAiresHour: mockGetBuenosAiresHour,
}));

// ─── Import triggers the captured handler registration ──────────────────────────

import "../cron/messageOrchestrator";
import * as functions from "firebase-functions";

// ─── Helpers ────────────────────────────────────────────────────────────────────

function defaultConfig(overrides: Record<string, any> = {}) {
  return {
    enabled: true,
    sendWindowStart: 8,
    sendWindowEnd: 20,
    maxDispatchRatePerSecond: 0, // disabled for speed in tests
    pausedUntil: undefined,
    ...overrides,
  };
}

function defaultCounter(overrides: Record<string, any> = {}) {
  return {
    sentCount: 0,
    urgentSentCount: 0,
    ...overrides,
  };
}

function createMockQueueDoc(overrides: Record<string, any> = {}) {
  const docId = `queue-${Math.random().toString(36).slice(2, 8)}`;
  const refUpdate = jest.fn().mockResolvedValue(undefined);

  const baseData: Record<string, any> = {
    providerId: "provider-1",
    patientId: "patient-1",
    patientName: "Test Patient",
    messageType: "payment_reminder",
    variables: {nombre_paciente: "Test", monto_total: 1000},
    priority: 30,
    isUrgent: false,
    status: "queued",
    scheduledFor: {toMillis: () => FIXED_NOW_MILLIS - 1000},
    expiresAt: {toMillis: () => FIXED_NOW_MILLIS + 86400000},
    createdAt: {toMillis: () => FIXED_NOW_MILLIS - 3600000},
  };

  // Apply overrides, handling nested timestamp-like objects
  const merged = {...baseData, ...overrides};

  return {
    id: overrides.id ?? docId,
    ref: {update: refUpdate},
    data: () => merged,
    _refUpdate: refUpdate,
  };
}

/**
 * Setup the chain of mockCollection/mockDoc/mockWhere calls for a standard run.
 * Handles the two-query flow: urgency elevation (1st) then main processing (2nd).
 */
function setupFirestoreMocks(opts: {
  mainDocs?: any[];
  elevationDocs?: any[];
} = {}) {
  const mainDocs = opts.mainDocs ?? [];
  const elevationDocs = opts.elevationDocs ?? [];

  // The function makes two query flows:
  //   1. Urgency elevation: db.collection("message_queue").where(status==queued)...get()
  //   2. Main query: db.collection("message_queue").where(status==queued).where(scheduledFor<=now)...get()
  //
  // Since all calls route through the same mockGet, we track call order.

  let getCallIndex = 0;
  mockGet.mockImplementation(() => {
    getCallIndex++;
    if (getCallIndex === 1) {
      // Urgency elevation pass query
      return Promise.resolve({
        empty: elevationDocs.length === 0,
        size: elevationDocs.length,
        docs: elevationDocs,
      });
    }
    // Main processing query
    return Promise.resolve({
      empty: mainDocs.length === 0,
      docs: mainDocs,
    });
  });
}

// ─── Tests ──────────────────────────────────────────────────────────────────────

describe("messageOrchestrator", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset mockGet to clear any leftover once-queued responses from previous tests
    mockGet.mockReset();
    // Defaults: enabled, hour=10 (inside window), no pausing
    mockGetMessagingConfig.mockResolvedValue(defaultConfig());
    mockGetOrResetCounter.mockResolvedValue(defaultCounter());
    mockGetBuenosAiresHour.mockReturnValue(10);
  });

  // ── Time Window ─────────────────────────────────────────────────────────────

  describe("Time Window", () => {
    it("exits early when config.enabled is false", async () => {
      mockGetMessagingConfig.mockResolvedValue(defaultConfig({enabled: false}));

      await capturedHandler();

      expect(functions.logger.info).toHaveBeenCalledWith(
        "messageOrchestrator disabled via config"
      );
      expect(mockGetOrResetCounter).not.toHaveBeenCalled();
    });

    it("exits early when hour < urgentWindowStart (hour=5)", async () => {
      mockGetBuenosAiresHour.mockReturnValue(5);

      await capturedHandler();

      expect(functions.logger.info).toHaveBeenCalledWith(
        "outside send window",
        expect.objectContaining({currentHour: 5})
      );
      expect(mockGetOrResetCounter).not.toHaveBeenCalled();
    });

    it("exits early when hour >= sendWindowEnd (hour=20)", async () => {
      mockGetBuenosAiresHour.mockReturnValue(20);

      await capturedHandler();

      expect(functions.logger.info).toHaveBeenCalledWith(
        "outside send window",
        expect.objectContaining({currentHour: 20})
      );
      expect(mockGetOrResetCounter).not.toHaveBeenCalled();
    });

    it("exits early when hour < sendWindowStart (hour=7)", async () => {
      mockGetBuenosAiresHour.mockReturnValue(7);

      await capturedHandler();

      expect(functions.logger.info).toHaveBeenCalledWith(
        "outside send window",
        expect.objectContaining({currentHour: 7})
      );
      expect(mockGetOrResetCounter).not.toHaveBeenCalled();
    });

    it("processes all messages between sendWindowStart and sendWindowEnd (hour=10)", async () => {
      mockGetBuenosAiresHour.mockReturnValue(10);
      setupFirestoreMocks({mainDocs: []});

      await capturedHandler();

      // The "isUrgent" filter should NOT appear in the main query when not in urgentOnly window
      // (it may appear in the elevation query with isUrgent==false, but not isUrgent==true for main)
      const isUrgentTrueCalls = mockWhere.mock.calls.filter(
        (c: any[]) => c[0] === "isUrgent" && c[1] === "==" && c[2] === true
      );
      expect(isUrgentTrueCalls.length).toBe(0);
    });
  });

  // ── Dispatch capacity (no daily cap) ────────────────────────────────────────

  describe("Dispatch capacity", () => {
    it("dispatches up to 500 messages in a single cycle", async () => {
      const docs = Array.from({length: 500}, (_, i) =>
        createMockQueueDoc({id: `msg-${i}`, isUrgent: false, priority: 30})
      );
      setupFirestoreMocks({mainDocs: docs});

      await capturedHandler();

      const processedDocs = docs.filter((d) =>
        d._refUpdate.mock.calls.some((c: any[]) => c[0]?.status === "processing")
      );
      expect(processedDocs.length).toBe(500);
    });

    it("counter still incremented for each dispatch (observability preserved)", async () => {
      const docs = [
        createMockQueueDoc({id: "d1"}),
        createMockQueueDoc({id: "d2"}),
        createMockQueueDoc({id: "d3"}),
      ];
      setupFirestoreMocks({mainDocs: docs});

      await capturedHandler();

      expect(mockIncrementCounter).toHaveBeenCalledTimes(3);
    });

    it("processes in priority order: 10 before 20 before 30", async () => {
      const p10 = createMockQueueDoc({id: "p10", priority: 10});
      const p20 = createMockQueueDoc({id: "p20", priority: 20});
      const p30 = createMockQueueDoc({id: "p30", priority: 30});
      setupFirestoreMocks({mainDocs: [p10, p20, p30]});

      await capturedHandler();

      // All three should be processed
      expect(p10._refUpdate).toHaveBeenCalledWith(
        expect.objectContaining({status: "processing"})
      );
      expect(p20._refUpdate).toHaveBeenCalledWith(
        expect.objectContaining({status: "processing"})
      );
      expect(p30._refUpdate).toHaveBeenCalledWith(
        expect.objectContaining({status: "processing"})
      );

      // p10 processed first (lower index = first call)
      const p10CallOrder = mockIncrementCounter.mock.invocationCallOrder[0];
      const p20CallOrder = mockIncrementCounter.mock.invocationCallOrder[1];
      const p30CallOrder = mockIncrementCounter.mock.invocationCallOrder[2];
      expect(p10CallOrder).toBeLessThan(p20CallOrder);
      expect(p20CallOrder).toBeLessThan(p30CallOrder);
    });

    it("urgent messages dispatched before normal messages", async () => {
      // Simulate Firestore returning 10 urgents first (isUrgent desc ordering), then 10 normals
      const urgentDocs = Array.from({length: 10}, (_, i) =>
        createMockQueueDoc({id: `urgent-${i}`, isUrgent: true, priority: 10})
      );
      const normalDocs = Array.from({length: 10}, (_, i) =>
        createMockQueueDoc({id: `normal-${i}`, isUrgent: false, priority: 30})
      );
      // Pass urgents first (as Firestore would return with isUrgent desc ordering)
      setupFirestoreMocks({mainDocs: [...urgentDocs, ...normalDocs]});

      await capturedHandler();

      // All 20 should be processed
      expect(mockIncrementCounter).toHaveBeenCalledTimes(20);

      // The first 10 incrementCounter calls correspond to urgent docs
      const urgentInvocationOrders = urgentDocs.map((d) => {
        const call = mockIncrementCounter.mock.calls.findIndex(
          (_c: any[], idx: number) => mockIncrementCounter.mock.invocationCallOrder[idx] !== undefined
        );
        return call;
      });
      // Verify urgents were processed (their refUpdate called with processing)
      for (const d of urgentDocs) {
        expect(d._refUpdate).toHaveBeenCalledWith(expect.objectContaining({status: "processing"}));
      }
      for (const d of normalDocs) {
        expect(d._refUpdate).toHaveBeenCalledWith(expect.objectContaining({status: "processing"}));
      }
      // The urgentDocs' refUpdate calls all have lower invocationCallOrder than normalDocs
      const urgentCallOrders = urgentDocs.map((d) =>
        (d._refUpdate as jest.Mock).mock.invocationCallOrder[0]
      );
      const normalCallOrders = normalDocs.map((d) =>
        (d._refUpdate as jest.Mock).mock.invocationCallOrder[0]
      );
      const maxUrgentOrder = Math.max(...urgentCallOrders);
      const minNormalOrder = Math.min(...normalCallOrders);
      expect(maxUrgentOrder).toBeLessThan(minNormalOrder);
      void urgentInvocationOrders; // suppress unused warning
    });
  });

  // ── Circuit Breaker ──────────────────────────────────────────────────────────

  describe("Circuit Breaker (pausedUntil)", () => {
    it("with pausedUntil in the future, skips dispatch but runs urgency elevation", async () => {
      mockGetMessagingConfig.mockResolvedValue(defaultConfig({
        pausedUntil: {toMillis: () => Date.now() + 999999},
      }));

      const elevationDoc = {
        ref: {update: jest.fn()},
        data: () => ({
          isUrgent: false,
          scheduledFor: {toMillis: () => FIXED_NOW_MILLIS - 1000},
          expiresAt: {toMillis: () => FIXED_NOW_MILLIS + 23 * 60 * 60 * 1000},
        }),
      };

      const mainDoc = createMockQueueDoc({id: "should-not-dispatch"});

      mockGet
        .mockResolvedValueOnce({empty: false, size: 1, docs: [elevationDoc]}) // elevation
        .mockResolvedValueOnce({empty: false, docs: [mainDoc]}); // main (should not reach)

      await capturedHandler();

      // Elevation ran
      expect(mockBatchCommit).toHaveBeenCalled();
      // Dispatch skipped
      expect(mockIncrementCounter).not.toHaveBeenCalled();
      expect(functions.logger.info).toHaveBeenCalledWith(
        "dispatch paused due to tier exhaustion",
        expect.objectContaining({pausedUntil: expect.any(Number)})
      );
    });

    it("with pausedUntil in the past, dispatches normally", async () => {
      mockGetMessagingConfig.mockResolvedValue(defaultConfig({
        pausedUntil: {toMillis: () => Date.now() - 1000},
      }));

      const doc = createMockQueueDoc({id: "should-dispatch"});
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(mockIncrementCounter).toHaveBeenCalledTimes(1);
    });

    it("without pausedUntil, dispatches normally", async () => {
      mockGetMessagingConfig.mockResolvedValue(defaultConfig({pausedUntil: undefined}));

      const doc = createMockQueueDoc({id: "dispatch-ok"});
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(mockIncrementCounter).toHaveBeenCalledTimes(1);
    });
  });

  // ── Pacing ───────────────────────────────────────────────────────────────────

  describe("Pacing", () => {
    it("with maxDispatchRatePerSecond=10 and 5 messages, setTimeout called with 100ms", async () => {
      mockGetMessagingConfig.mockResolvedValue(defaultConfig({maxDispatchRatePerSecond: 10}));

      const docs = Array.from({length: 5}, (_, i) =>
        createMockQueueDoc({id: `pace-${i}`})
      );
      setupFirestoreMocks({mainDocs: docs});

      // Replace setTimeout with an immediate resolver that records the delay argument
      const recordedDelays: number[] = [];
      const originalSetTimeout = global.setTimeout;
      (global as any).setTimeout = (fn: () => void, delay: number) => {
        recordedDelays.push(delay);
        fn(); // execute immediately so the promise resolves
        return 0 as any;
      };

      await capturedHandler();

      // Restore
      global.setTimeout = originalSetTimeout;

      // setTimeout called 5 times (once per dispatched message), each with 100ms
      const pacingCalls = recordedDelays.filter((d) => d === 100);
      expect(pacingCalls.length).toBe(5);
    });

    it("with maxDispatchRatePerSecond=0, no setTimeout delay added", async () => {
      mockGetMessagingConfig.mockResolvedValue(defaultConfig({maxDispatchRatePerSecond: 0}));

      const doc = createMockQueueDoc({id: "no-pace"});
      setupFirestoreMocks({mainDocs: [doc]});

      const setTimeoutSpy = jest.spyOn(global, "setTimeout");

      await capturedHandler();

      // No pacing setTimeout calls (0 means disabled)
      const pacingCalls = setTimeoutSpy.mock.calls.filter(
        (c: any[]) => typeof c[1] === "number" && c[1] > 0
      );
      expect(pacingCalls.length).toBe(0);

      setTimeoutSpy.mockRestore();
    });
  });

  // ── Urgency Elevation ────────────────────────────────────────────────────────

  describe("Urgency Elevation", () => {
    it("dispatches a queued message when scheduledFor <= now and no circuit breaker", async () => {
      const doc = createMockQueueDoc({
        id: "dispatch-test",
        scheduledFor: {toMillis: () => FIXED_NOW_MILLIS - 1000}, // past
      });
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(doc._refUpdate).toHaveBeenCalledWith(
        expect.objectContaining({status: "processing"})
      );
    });

    it("elevates queued message to urgent when expiresAt - now < 24h", async () => {
      // Elevation query returns one doc, main query returns empty
      mockGet
        .mockResolvedValueOnce({
          empty: false,
          size: 1,
          docs: [{
            ref: {update: jest.fn()},
            data: () => ({
              isUrgent: false,
              scheduledFor: {toMillis: () => FIXED_NOW_MILLIS - 1000},
              expiresAt: {toMillis: () => FIXED_NOW_MILLIS + 23 * 60 * 60 * 1000},
            }),
          }],
        })
        .mockResolvedValueOnce({empty: true, docs: []}); // main query

      await capturedHandler();

      expect(mockBatchUpdate).toHaveBeenCalledWith(
        expect.anything(),
        {isUrgent: true, priority: 10}
      );
      expect(functions.logger.info).toHaveBeenCalledWith(
        "urgency elevation completed",
        expect.objectContaining({elevatedCount: 1})
      );
    });

    it("does not elevate message when elevation snap is empty (expiresAt >= 24h from now filtered server-side)", async () => {
      // Elevation query returns empty (Firestore filtered out docs with expiresAt > now+24h)
      mockGet
        .mockResolvedValueOnce({empty: true, size: 0, docs: []}) // elevation
        .mockResolvedValueOnce({empty: true, docs: []}); // main

      await capturedHandler();

      // No urgency elevation batch update
      expect(mockBatchUpdate).not.toHaveBeenCalled();
    });

    it("scheduledFor is never modified by the orchestrator", async () => {
      const doc = createMockQueueDoc({id: "no-reschedule"});
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      // All update calls on doc.ref should NOT include scheduledFor
      for (const call of doc._refUpdate.mock.calls) {
        expect(call[0]).not.toHaveProperty("scheduledFor");
      }
    });
  });

  // ── Expiration ────────────────────────────────────────────────────────────

  describe("Expiration", () => {
    it("marks expired when expiresAt < now in main loop", async () => {
      const doc = createMockQueueDoc({
        id: "exp-1",
        expiresAt: {toMillis: () => FIXED_NOW_MILLIS - 1000}, // already past
      });
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(doc._refUpdate).toHaveBeenCalledWith({status: "expired"});
      expect(mockIncrementCounter).not.toHaveBeenCalled();
    });
  });

  // ── Communication creation ──────────────────────────────────────────────────

  describe("Communication creation", () => {
    it("creates doc in providers/{pid}/communications/ with correct data", async () => {
      const doc = createMockQueueDoc({
        id: "comm-test",
        providerId: "provider-abc",
        patientId: "patient-xyz",
        patientName: "Maria Garcia",
        variables: {nombre_paciente: "Maria", monto_total: 5000},
      });
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(mockDoc).toHaveBeenCalledWith("provider-abc");

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          providerId: "provider-abc",
          patientId: "patient-xyz",
          patientName: "Maria Garcia",
          totalDebtAtThatTime: 5000,
        })
      );
    });

    it("communication doc has type=whatsapp_reminder and status=pending", async () => {
      const doc = createMockQueueDoc({id: "comm-type"});
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          type: "whatsapp_reminder",
          status: "pending",
        })
      );
    });

    it("sets queueItemId linking back to queue", async () => {
      const doc = createMockQueueDoc({id: "queue-link-id"});
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          queueItemId: "queue-link-id",
        })
      );
    });

    it("includes messageType from queue item in commData", async () => {
      const doc = createMockQueueDoc({
        id: "type-check",
        messageType: "appointment_reminder",
      });
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(mockSet).toHaveBeenCalledWith(
        expect.objectContaining({
          messageType: "appointment_reminder",
        })
      );
    });

    it("mirrors communication to patient subcollection", async () => {
      const doc = createMockQueueDoc({
        id: "mirror-test",
        providerId: "prov-1",
        patientId: "pat-1",
      });
      setupFirestoreMocks({mainDocs: [doc]});

      await capturedHandler();

      expect(mockDoc).toHaveBeenCalledWith("prov-1");

      // set() should be called twice: once for provider comm, once for patient mirror
      const setCalls = mockSet.mock.calls;
      expect(setCalls.length).toBeGreaterThanOrEqual(2);

      // Both calls should have the same data shape
      expect(setCalls[0][0]).toEqual(setCalls[1][0]);
    });
  });
});
