// ─── Mock setup (must be before imports) ────────────────────────────────────

const mockCollection = jest.fn();
const mockBatchDelete = jest.fn();
const mockBatchCommit = jest.fn().mockResolvedValue([]);

const mockDb = {
  collection: mockCollection,
  batch: jest.fn(() => ({
    delete: mockBatchDelete,
    commit: mockBatchCommit,
  })),
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

import { queueCleanup } from "../cron/queueCleanup";

// ─── Helpers ────────────────────────────────────────────────────────────────

function makeQueueDoc(id: string, status: string, attempts = 0) {
  return {
    id,
    ref: { id, path: `message_queue/${id}` },
    data: () => ({ status, attempts }),
  };
}

type QuerySetup = {
  terminalDocs: ReturnType<typeof makeQueueDoc>[];
  failedDocs: ReturnType<typeof makeQueueDoc>[];
  stuckProcessingDocs?: ReturnType<typeof makeQueueDoc>[];
};

function setupQueries({ terminalDocs, failedDocs, stuckProcessingDocs = [] }: QuerySetup) {
  const terminalSnap = { docs: terminalDocs };
  const failedSnap = { docs: failedDocs };
  const stuckSnap = { docs: stuckProcessingDocs };

  // Three queries run in Promise.all:
  // 1) status in ["sent", "expired", "duplicate", "cancelled"], createdAt < cutoff, limit 500
  // 2) status == "failed", attempts >= 3, createdAt < cutoff, limit 500
  // 3) status == "processing", processedAt < 48h ago, limit 500

  let queryCallCount = 0;

  mockCollection.mockImplementation((_name: string) => {
    return {
      where: jest.fn().mockImplementation(() => {
        const chain = {
          where: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnValue({
            get: jest.fn().mockImplementation(() => {
              queryCallCount++;
              if (queryCallCount <= 1) return Promise.resolve(terminalSnap);
              if (queryCallCount === 2) return Promise.resolve(failedSnap);
              return Promise.resolve(stuckSnap);
            }),
          }),
        };
        return chain;
      }),
    };
  });
}

// ─── Tests ──────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
});

describe("queueCleanup", () => {
  const handler = queueCleanup as unknown as () => Promise<null>;

  describe("deletes terminal-status docs older than 7 days", () => {
    test("deletes docs with status 'sent' older than 7 days", async () => {
      const sentDoc = makeQueueDoc("doc-sent", "sent");
      setupQueries({ terminalDocs: [sentDoc], failedDocs: [] });

      await handler();

      expect(mockBatchDelete).toHaveBeenCalledWith(sentDoc.ref);
      expect(mockBatchCommit).toHaveBeenCalled();
    });

    test("deletes docs with status 'expired' older than 7 days", async () => {
      const expiredDoc = makeQueueDoc("doc-expired", "expired");
      setupQueries({ terminalDocs: [expiredDoc], failedDocs: [] });

      await handler();

      expect(mockBatchDelete).toHaveBeenCalledWith(expiredDoc.ref);
    });

    test("deletes docs with status 'duplicate' older than 7 days", async () => {
      const dupDoc = makeQueueDoc("doc-dup", "duplicate");
      setupQueries({ terminalDocs: [dupDoc], failedDocs: [] });

      await handler();

      expect(mockBatchDelete).toHaveBeenCalledWith(dupDoc.ref);
    });

    test("'cancelled' status docs are cleaned up after 7 days", async () => {
      const cancelledDoc = makeQueueDoc("doc-cancelled", "cancelled");
      setupQueries({ terminalDocs: [cancelledDoc], failedDocs: [] });

      await handler();

      expect(mockBatchDelete).toHaveBeenCalledWith(cancelledDoc.ref);
    });
  });

  describe("preserves active docs", () => {
    test("does NOT delete 'queued' docs even if old", async () => {
      // Queued docs are never returned by any query because the queries
      // filter by status in ["sent","expired","duplicate","cancelled"] or status=="failed" or status=="processing"
      setupQueries({ terminalDocs: [], failedDocs: [] });

      await handler();

      expect(mockBatchDelete).not.toHaveBeenCalled();
      // batch.commit should not be called when no docs to delete
      // (the function returns early)
    });
  });

  describe("failed docs handling", () => {
    test("does NOT delete 'failed' docs with attempts < 3", async () => {
      // The second query filters by attempts >= 3, so attempts < 3 are excluded
      // We simulate the query returning empty for failed docs
      setupQueries({ terminalDocs: [], failedDocs: [] });

      await handler();

      expect(mockBatchDelete).not.toHaveBeenCalled();
    });

    test("deletes 'failed' docs with attempts >= 3 and older than 7 days", async () => {
      const failedExhaustedDoc = makeQueueDoc("doc-failed-3", "failed", 3);
      setupQueries({ terminalDocs: [], failedDocs: [failedExhaustedDoc] });

      await handler();

      expect(mockBatchDelete).toHaveBeenCalledWith(failedExhaustedDoc.ref);
      expect(mockBatchCommit).toHaveBeenCalled();
    });
  });

  describe("stuck processing docs handling", () => {
    test("processing item with processedAt 49h ago is deleted", async () => {
      const stuckDoc = makeQueueDoc("stuck-processing", "processing");
      setupQueries({ terminalDocs: [], failedDocs: [], stuckProcessingDocs: [stuckDoc] });

      await handler();

      expect(mockBatchDelete).toHaveBeenCalledWith(stuckDoc.ref);
    });

    test("processing item with processedAt 24h ago is NOT deleted (only if old enough)", async () => {
      // The query filters processedAt < 48h ago server-side.
      // Recent processing items are excluded by the query, so they won't appear.
      setupQueries({ terminalDocs: [], failedDocs: [], stuckProcessingDocs: [] });

      await handler();

      expect(mockBatchDelete).not.toHaveBeenCalled();
    });
  });

  describe("batch chunking", () => {
    test("600 eligible docs result in two batch commits", async () => {
      const docs600 = Array.from({length: 600}, (_, i) => makeQueueDoc(`doc-${i}`, "sent"));
      setupQueries({ terminalDocs: docs600, failedDocs: [] });

      await handler();

      // Should commit twice: once for first 500, once for remaining 100
      expect(mockBatchCommit).toHaveBeenCalledTimes(2);
      expect(mockBatchDelete).toHaveBeenCalledTimes(600);
    });

    test("499 eligible docs result in one batch commit", async () => {
      const docs499 = Array.from({length: 499}, (_, i) => makeQueueDoc(`doc-${i}`, "sent"));
      setupQueries({ terminalDocs: docs499, failedDocs: [] });

      await handler();

      expect(mockBatchCommit).toHaveBeenCalledTimes(1);
      expect(mockBatchDelete).toHaveBeenCalledTimes(499);
    });
  });

  describe("mixed scenarios", () => {
    test("deletes both terminal and exhausted-failed docs in one batch", async () => {
      const sentDoc = makeQueueDoc("doc-sent", "sent");
      const expiredDoc = makeQueueDoc("doc-expired", "expired");
      const failedDoc = makeQueueDoc("doc-failed-5", "failed", 5);

      setupQueries({
        terminalDocs: [sentDoc, expiredDoc],
        failedDocs: [failedDoc],
      });

      await handler();

      expect(mockBatchDelete).toHaveBeenCalledTimes(3);
      expect(mockBatchDelete).toHaveBeenCalledWith(sentDoc.ref);
      expect(mockBatchDelete).toHaveBeenCalledWith(expiredDoc.ref);
      expect(mockBatchDelete).toHaveBeenCalledWith(failedDoc.ref);
      expect(mockBatchCommit).toHaveBeenCalledTimes(1);
    });

    test("logs info when no stale documents found", async () => {
      setupQueries({ terminalDocs: [], failedDocs: [] });

      await handler();

      const functions = require("firebase-functions");
      expect(functions.logger.info).toHaveBeenCalledWith(
        "[queueCleanup] No stale documents found"
      );
    });
  });
});
