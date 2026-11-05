import * as admin from "firebase-admin";

const db = admin.firestore();

const MAX_BATCH_OPS = 450;

/**
 * Utility class for batched Firestore writes.
 *
 * Automatically splits writes into multiple batches when the Firestore
 * limit of 500 operations per batch is approached (threshold: 450).
 * Call `flush()` at the end of any operation that uses this class.
 */
export class BatchWriter {
  private batch = db.batch();
  private opCount = 0;
  private commits: Array<Promise<FirebaseFirestore.WriteResult[]>> = [];

  async set(
    ref: FirebaseFirestore.DocumentReference,
    data: FirebaseFirestore.DocumentData
  ) {
    this.batch.set(ref, data);
    this.opCount++;
    await this.flushIfNeeded();
  }

  async update(
    ref: FirebaseFirestore.DocumentReference,
    data: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>
  ) {
    this.batch.update(ref, data);
    this.opCount++;
    await this.flushIfNeeded();
  }

  private async flushIfNeeded() {
    if (this.opCount >= MAX_BATCH_OPS) {
      this.commits.push(this.batch.commit());
      this.batch = db.batch();
      this.opCount = 0;
    }
  }

  async flush() {
    if (this.opCount > 0) {
      this.commits.push(this.batch.commit());
      this.batch = db.batch();
      this.opCount = 0;
    }
    await Promise.all(this.commits);
  }
}
