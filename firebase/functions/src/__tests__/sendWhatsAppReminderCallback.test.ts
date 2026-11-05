// ─── Mock twilio (must be before any import) ────────────────────────────────

const mockTwilioCreate = jest.fn();

jest.mock("twilio", () => {
  return jest.fn(() => ({
    messages: {
      create: mockTwilioCreate,
    },
  }));
});

// ─── Mock messaging_utils ────────────────────────────────────────────────────

const mockResolveTemplateContentSid = jest.fn();
const mockBuildTwilioContentVariables = jest.fn();
const mockGetMessagingConfig = jest.fn();

// Local replica of the error class so instanceof works correctly in mocks
class MockTemplateNotConfiguredError extends Error {
  constructor(providerId: string, messageType: string) {
    super(`No Content SID configured for messageType="${messageType}" (providerId="${providerId}")`);
    this.name = "TemplateNotConfiguredError";
  }
}

jest.mock("../utils/messaging_utils", () => ({
  resolveTemplateContentSid: (...args: unknown[]) => mockResolveTemplateContentSid(...args),
  buildTwilioContentVariables: (...args: unknown[]) => mockBuildTwilioContentVariables(...args),
  getMessagingConfig: (...args: unknown[]) => mockGetMessagingConfig(...args),
  TemplateNotConfiguredError: MockTemplateNotConfiguredError,
  normalizeArgentinePhone: (phone: string) => phone, // passthrough — normalization tested separately
}));

// ─── Mock firebase-admin ─────────────────────────────────────────────────────

const mockSnapUpdate = jest.fn().mockResolvedValue(undefined);
const mockSnapDelete = jest.fn().mockResolvedValue(undefined);
const mockPatientCommSet = jest.fn().mockResolvedValue(undefined);
const mockPatientCommDelete = jest.fn().mockResolvedValue(undefined);
const mockQueueUpdate = jest.fn().mockResolvedValue(undefined);
const mockMetadataSet = jest.fn().mockResolvedValue(undefined);
const mockCollection = jest.fn();

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
    delete: jest.fn(() => "DELETE"),
  };
  return {
    firestore: mockFirestore,
    initializeApp: jest.fn(),
  };
});

// ─── Mock firebase-functions ─────────────────────────────────────────────────

jest.mock("firebase-functions", () => ({
  runWith: jest.fn(() => ({
    firestore: {
      document: jest.fn(() => ({
        onCreate: jest.fn((handler: Function) => handler),
      })),
    },
  })),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

// ─── Imports (after mocks) ──────────────────────────────────────────────────

import { sendWhatsAppReminder } from "../workers/sendWhatsAppReminder";

// ─── Type alias ─────────────────────────────────────────────────────────────

const handler = sendWhatsAppReminder as unknown as (
  snap: any,
  ctx: any
) => Promise<null>;

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeCommSnap(data: Record<string, unknown>, snapDeleteFn?: jest.Mock) {
  return {
    data: () => data,
    ref: {
      update: mockSnapUpdate,
      delete: snapDeleteFn ?? mockSnapDelete,
    },
  };
}

function makeContext(providerId: string, commId: string) {
  return {
    params: { providerId, commId },
  };
}

/**
 * Wire up Firestore mock chains for the new Twilio-based implementation.
 *
 * Chains handled:
 *   db.collection("providers").doc(pid).get()                                -> provider snap
 *   db.collection("providers").doc(pid).collection("patients").doc(pat).get()  -> patient snap
 *   db.collection("providers").doc(pid).collection("patients").doc(pat)
 *       .collection("communications").doc(commId).set(...)                   -> mirrorPatientUpdate
 *   db.collection("message_queue").doc(queueItemId).update(...)              -> queue update
 */
function setupMocks({
  subscriptionStatus = "active",
  phone = "+5491100000000",
  queueUpdateError = undefined as Error | undefined,
}: {
  subscriptionStatus?: string;
  phone?: string | null;
  queueUpdateError?: Error;
} = {}) {
  const providerSnap = {
    exists: true,
    data: () => ({ subscriptionStatus }),
  };

  const patientSnap = {
    exists: true,
    data: () => (phone ? { phoneNumber: phone } : {}),
  };

  mockCollection.mockImplementation((name: string) => {
    if (name === "providers") {
      return {
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue(providerSnap),
          collection: jest.fn().mockImplementation((subName: string) => {
            if (subName === "patients") {
              return {
                doc: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue(patientSnap),
                  collection: jest.fn().mockReturnValue({
                    doc: jest.fn().mockReturnValue({
                      set: mockPatientCommSet,
                      delete: mockPatientCommDelete,
                    }),
                  }),
                }),
              };
            }
            return {};
          }),
        }),
      };
    }
    if (name === "message_queue") {
      const queueDoc = {
        update: queueUpdateError
          ? jest.fn().mockRejectedValue(queueUpdateError)
          : mockQueueUpdate,
      };
      return {
        doc: jest.fn().mockReturnValue(queueDoc),
      };
    }
    if (name === "metadata") {
      return {
        doc: jest.fn().mockReturnValue({
          set: mockMetadataSet,
        }),
      };
    }
    return {};
  });

  // Default getMessagingConfig for rollback tests
  mockGetMessagingConfig.mockResolvedValue({
    tierExhaustedPauseMs: 30 * 60 * 1000,
  });
}

// ─── Tests ──────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  // Default: resolveTemplateContentSid succeeds, buildTwilioContentVariables returns vars
  mockResolveTemplateContentSid.mockResolvedValue("HX_test_sid");
  mockBuildTwilioContentVariables.mockReturnValue({ "1": "Ana", "4": "10:00" });
});

describe("sendWhatsAppReminder — Twilio integration", () => {
  describe("early exits", () => {
    test("status !== pending: returns null without any Firestore writes", async () => {
      setupMocks();
      const snap = makeCommSnap({
        status: "sent",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      await handler(snap, makeContext("prov-1", "comm-1"));

      expect(mockTwilioCreate).not.toHaveBeenCalled();
      expect(mockSnapUpdate).not.toHaveBeenCalled();
    });

    test("type !== whatsapp_reminder: returns null without any Firestore writes", async () => {
      setupMocks();
      const snap = makeCommSnap({
        status: "pending",
        type: "sms_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      await handler(snap, makeContext("prov-1", "comm-1"));

      expect(mockTwilioCreate).not.toHaveBeenCalled();
      expect(mockSnapUpdate).not.toHaveBeenCalled();
    });
  });

  describe("subscription check", () => {
    test("subscription inactive: status='aborted', reason='subscription_inactive', Twilio NOT called", async () => {
      setupMocks({ subscriptionStatus: "suspended" });
      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      await handler(snap, makeContext("prov-1", "comm-1"));

      expect(mockTwilioCreate).not.toHaveBeenCalled();
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "aborted", reason: "subscription_inactive" })
      );
      // mirrorPatientUpdate should also be called
      expect(mockPatientCommSet).toHaveBeenCalledWith(
        expect.objectContaining({ status: "aborted", reason: "subscription_inactive" }),
        { merge: true }
      );
    });
  });

  describe("phone validation", () => {
    test("no phone: status='aborted', reason='no_phone', Twilio NOT called", async () => {
      setupMocks({ phone: null });
      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      await handler(snap, makeContext("prov-1", "comm-1"));

      expect(mockTwilioCreate).not.toHaveBeenCalled();
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "aborted", reason: "no_phone" })
      );
      expect(mockPatientCommSet).toHaveBeenCalledWith(
        expect.objectContaining({ status: "aborted", reason: "no_phone" }),
        { merge: true }
      );
    });
  });

  describe("template resolution", () => {
    test("TemplateNotConfiguredError: status='aborted', reason='template_not_configured', Twilio NOT called", async () => {
      setupMocks();
      mockResolveTemplateContentSid.mockRejectedValue(
        new MockTemplateNotConfiguredError("prov-1", "appointment_reminder")
      );

      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      await handler(snap, makeContext("prov-1", "comm-1"));

      expect(mockTwilioCreate).not.toHaveBeenCalled();
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "aborted", reason: "template_not_configured" })
      );
      expect(mockPatientCommSet).toHaveBeenCalledWith(
        expect.objectContaining({ status: "aborted", reason: "template_not_configured" }),
        { merge: true }
      );
    });
  });

  describe("successful send", () => {
    test("Twilio success: status='sent', messageId=messageSid, deliveredAt=SERVER_TIMESTAMP", async () => {
      setupMocks();
      mockTwilioCreate.mockResolvedValue({ sid: "MSG_SUCCESS" });

      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: { nombre_paciente: "Ana", fecha_turno: "24/03/2026", hora_turno: "10:00" },
      });

      await handler(snap, makeContext("prov-1", "comm-1"));

      expect(mockTwilioCreate).toHaveBeenCalledTimes(1);
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "sent", messageId: "MSG_SUCCESS", deliveredAt: "SERVER_TIMESTAMP" })
      );
      expect(mockPatientCommSet).toHaveBeenCalledWith(
        expect.objectContaining({ status: "sent", messageId: "MSG_SUCCESS" }),
        { merge: true }
      );
      expect(mockQueueUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "sent", processedAt: "SERVER_TIMESTAMP" })
      );
    });
  });

  describe("retry logic", () => {
    test("Twilio 429 on attempt 1, success on attempt 2: status='sent'", async () => {
      setupMocks();
      mockTwilioCreate
        .mockRejectedValueOnce({ status: 429, message: "Too Many Requests" })
        .mockResolvedValueOnce({ sid: "MSG_SID_RETRY" });

      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      jest.useFakeTimers();
      const promise = handler(snap, makeContext("prov-1", "comm-1"));
      await jest.runAllTimersAsync();
      await promise;
      jest.useRealTimers();

      expect(mockTwilioCreate).toHaveBeenCalledTimes(2);
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "sent", messageId: "MSG_SID_RETRY" })
      );
    });

    test("3 consecutive Twilio 500 failures: status='failed', lastError present", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ status: 500, message: "Internal Server Error" });

      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      jest.useFakeTimers();
      const promise = handler(snap, makeContext("prov-1", "comm-1"));
      await jest.runAllTimersAsync();
      await promise;
      jest.useRealTimers();

      expect(mockTwilioCreate).toHaveBeenCalledTimes(3);
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "failed", lastError: expect.any(String) })
      );
    });

    test("Twilio 400 non-retriable: fails immediately, Twilio called only once", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ status: 400, message: "Bad Request" });

      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-1",
        messageType: "appointment_reminder",
        variables: {},
      });

      await handler(snap, makeContext("prov-1", "comm-1"));

      expect(mockTwilioCreate).toHaveBeenCalledTimes(1);
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "failed" })
      );
    });
  });

  describe("Meta tier exhaustion rollback", () => {
    function makePendingSnap(queueItemId = "q-tier") {
      return makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId,
        messageType: "payment_reminder",
        variables: {},
      });
    }

    test("error code 63038 → comm doc deleted, queue item reset to queued, processedAt cleared, attempts unchanged, pausedUntil set", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ code: 63038, message: "Daily message limit reached" });

      const snap = makePendingSnap("q-63038");
      await handler(snap, makeContext("prov-1", "comm-63038"));

      // Comm doc deleted
      expect(mockSnapDelete).toHaveBeenCalledTimes(1);
      // Patient mirror deleted
      expect(mockPatientCommDelete).toHaveBeenCalledTimes(1);
      // Queue item reset to queued with processedAt removed, no attempts increment
      expect(mockQueueUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: "queued",
          processedAt: "DELETE",
        })
      );
      // No attempts field in the update
      const queueUpdateCall = mockQueueUpdate.mock.calls[0][0];
      expect(queueUpdateCall).not.toHaveProperty("attempts");
      // pausedUntil set on metadata/messaging with merge
      expect(mockMetadataSet).toHaveBeenCalledWith(
        expect.objectContaining({ pausedUntil: expect.anything() }),
        { merge: true }
      );
      // Generic failed path NOT triggered
      expect(mockSnapUpdate).not.toHaveBeenCalled();
    });

    test("error code 63032 → same rollback as 63038", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ code: 63032, message: "Daily message limit reached" });

      const snap = makePendingSnap("q-63032");
      await handler(snap, makeContext("prov-1", "comm-63032"));

      expect(mockSnapDelete).toHaveBeenCalledTimes(1);
      expect(mockQueueUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "queued", processedAt: "DELETE" })
      );
      expect(mockMetadataSet).toHaveBeenCalledWith(
        expect.objectContaining({ pausedUntil: expect.anything() }),
        { merge: true }
      );
      expect(mockSnapUpdate).not.toHaveBeenCalled();
    });

    test("error 429 non-Meta → existing retry path, NOT tier rollback", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ status: 429, message: "Too Many Requests" });

      const snap = makePendingSnap("q-429");

      jest.useFakeTimers();
      const promise = handler(snap, makeContext("prov-1", "comm-429"));
      await jest.runAllTimersAsync();
      await promise;
      jest.useRealTimers();

      // Rollback NOT triggered
      expect(mockSnapDelete).not.toHaveBeenCalled();
      expect(mockMetadataSet).not.toHaveBeenCalled();
      // Generic failed path triggered
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "failed" })
      );
    });

    test("error 500 → existing retry path, NOT tier rollback", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ status: 500, message: "Internal Server Error" });

      const snap = makePendingSnap("q-500");

      jest.useFakeTimers();
      const promise = handler(snap, makeContext("prov-1", "comm-500"));
      await jest.runAllTimersAsync();
      await promise;
      jest.useRealTimers();

      expect(mockSnapDelete).not.toHaveBeenCalled();
      expect(mockMetadataSet).not.toHaveBeenCalled();
      expect(mockSnapUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "failed" })
      );
    });

    test("rollback is idempotent — calling handler twice with same snap does not throw", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ code: 63038, message: "Daily message limit reached" });

      const snapDelete = jest.fn().mockResolvedValue(undefined);
      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-idem",
        messageType: "payment_reminder",
        variables: {},
      }, snapDelete);

      await expect(handler(snap, makeContext("prov-1", "comm-idem"))).resolves.toBeNull();
      await expect(handler(snap, makeContext("prov-1", "comm-idem"))).resolves.toBeNull();
    });

    test("rollback with queue item already deleted → logs warn, does not throw", async () => {
      const notFoundError = new Error("NOT_FOUND");
      setupMocks({ queueUpdateError: notFoundError });
      mockTwilioCreate.mockRejectedValue({ code: 63038, message: "Daily message limit reached" });

      const snap = makePendingSnap("q-deleted");

      await expect(handler(snap, makeContext("prov-1", "comm-warn"))).resolves.toBeNull();

      // pausedUntil still written even if queue update fails
      expect(mockMetadataSet).toHaveBeenCalledWith(
        expect.objectContaining({ pausedUntil: expect.anything() }),
        { merge: true }
      );
    });

    test("pausedUntil written with merge:true — does not overwrite other metadata fields", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ code: 63038, message: "Daily message limit reached" });

      const snap = makePendingSnap("q-merge");
      await handler(snap, makeContext("prov-1", "comm-merge"));

      // The set call must use { merge: true }
      const setCall = mockMetadataSet.mock.calls[0];
      expect(setCall[1]).toEqual({ merge: true });
      // Should only set pausedUntil, not other fields
      expect(Object.keys(setCall[0])).toEqual(["pausedUntil"]);
    });
  });

  describe("Integration: full cycle with tier exhaustion", () => {
    test("9.1 + 9.2: after tier exhaustion rollback, queue item stays queued (ready for re-dispatch)", async () => {
      setupMocks();
      mockTwilioCreate.mockRejectedValue({ code: 63038, message: "Daily message limit reached" });

      const snap = makeCommSnap({
        status: "pending",
        type: "whatsapp_reminder",
        patientId: "pat-1",
        queueItemId: "q-integration",
        messageType: "payment_reminder",
        variables: {},
      });

      await handler(snap, makeContext("prov-1", "comm-integration"));

      // Queue item reset to queued (not failed, not processing) — ready for re-dispatch
      expect(mockQueueUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ status: "queued" })
      );
      // No attempts increment — same idempotencyKey will work on next dispatch
      const call = mockQueueUpdate.mock.calls[0][0];
      expect(call).not.toHaveProperty("attempts");
      // pausedUntil set — orchestrator will skip next cycle
      expect(mockMetadataSet).toHaveBeenCalledWith(
        expect.objectContaining({ pausedUntil: expect.anything() }),
        { merge: true }
      );
    });
  });
});
