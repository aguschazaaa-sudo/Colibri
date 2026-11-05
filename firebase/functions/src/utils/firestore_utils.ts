import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Fetches multiple Firestore documents in parallel chunks.
 *
 * Splits the refs array into chunks of the given size and fetches each
 * chunk concurrently (up to 5 workers). This avoids hitting Firestore's
 * limit of 30 document reads per `getAll()` call while still parallelizing
 * for performance.
 *
 * @param refs      Array of DocumentReferences to fetch.
 * @param chunkSize Maximum number of refs per `getAll()` call.
 * @returns         All DocumentSnapshots in the same order they were fetched
 *                  (chunk order is preserved; order within a chunk matches input).
 */
export async function getAllInChunks(
  refs: FirebaseFirestore.DocumentReference[],
  chunkSize: number
): Promise<FirebaseFirestore.DocumentSnapshot[]> {
  const docs: FirebaseFirestore.DocumentSnapshot[] = [];
  const chunks: FirebaseFirestore.DocumentReference[][] = [];
  for (let i = 0; i < refs.length; i += chunkSize) {
    chunks.push(refs.slice(i, i + chunkSize));
  }

  const concurrency = Math.min(5, chunks.length);
  let index = 0;

  async function worker() {
    while (index < chunks.length) {
      const chunk = chunks[index++];
      const chunkDocs = await db.getAll(...chunk);
      docs.push(...chunkDocs);
    }
  }

  const workers = Array.from({ length: concurrency }, () => worker());
  await Promise.all(workers);
  return docs;
}
