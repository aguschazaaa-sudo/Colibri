## Context

Appointments are pre-generated 2 days in advance by `dailyRecurringProcessor`. A `RecurringAppointment` document drives that generation; individual `Appointment` docs live under the patient subcollection. There is currently no mechanism for a professional to skip a single future or already-generated occurrence while keeping the rule active for all other dates.

`AppointmentStatus` already has a `cancelled` value but it is not used in the recurring flow. The domain model and cron have no concept of "exceptions".

## Goals / Non-Goals

**Goals:**
- Let a professional cancel a single occurrence of a recurring rule from the day-timeline view.
- Prevent the cron from generating an appointment on a cancelled date.
- Remove (or mark cancelled) any already-generated appointment for that occurrence + clean up its ledger entry.
- Hide the ghost card on the timeline for cancelled occurrences.

**Non-Goals:**
- Cancelling the entire recurring rule (deactivate the rule — existing flow).
- Undo / restore a cancelled occurrence (out of scope for now).
- Bulk cancellation of multiple occurrences at once.
- Patient-facing notifications for the cancellation.

## Decisions

### 1. Store cancelled dates on the `RecurringAppointment` document as `cancelledDates: string[]`

**Chosen:** Add a `cancelledDates` array of `dateKey` strings (e.g. `"2026-04-10"`) directly to the `RecurringAppointment` Firestore document.

**Rationale:**
- Single read path — the cron already reads the full recurring doc, so no extra query is needed.
- The timeline view already reads `RecurringAppointment` to compute ghost cards; checking `cancelledDates` is a no-op extra field access.
- Simpler than a sub-collection of exceptions; array size stays bounded (a professional rarely cancels more than a handful of sessions per year per rule, and Firestore array limits are 1 MB per doc, well within reach).

**Alternatives considered:**
- *Separate `cancelled_occurrences` subcollection:* More normalized, but requires an extra query from both the cron and the timeline. Overkill for the expected cardinality.
- *Marking the existing `Appointment` with `status: cancelled` and relying on cron idempotency:* Works only when the appointment is already generated. Does not handle the pre-generation case (cancelling a session that hasn't been created yet).

---

### 2. Cancel flow is a Firestore write — no new Cloud Function needed

**Chosen:** The Flutter app performs two Firestore writes in a single batch:
1. `arrayUnion` the `dateKey` into `cancelledDates` on the `RecurringAppointment` doc.
2. If an `Appointment` already exists for that `dateKey` (query by `recurringAppointmentId` + `dateKey`): delete the appointment doc and its ledger entry in the same batch.

**Rationale:**
- Keeps the feature purely client-driven with no cold-start latency.
- Both writes belong to the same logical transaction; batching gives atomicity within Firestore limits.
- Security rules can enforce that only the owning provider can write `cancelledDates`.

**Alternatives considered:**
- *Callable Cloud Function:* Adds latency and deployment complexity. Only justified if server-side validation beyond Firestore rules is needed — it isn't here.

---

### 3. Cron skip logic: check `cancelledDates` before creating

**Chosen:** In `processRecurringForTargetDate`, after the idempotency check, add:
```ts
if ((data.cancelledDates ?? []).includes(targetDateKey)) {
  // Still update lastGeneratedDate to avoid re-processing this date
  await recurringDoc.ref.update({ lastGeneratedDate: ... });
  continue;
}
```

**Rationale:** The existing idempotency check (`existingSnapshot`) handles the case where an appointment was already created; the `cancelledDates` check handles the pre-generation case. Both paths update `lastGeneratedDate` so the cron doesn't stall.

---

### 4. Ghost card suppression in the timeline

**Chosen:** The ghost-card projection logic (in the Riverpod provider that merges `RecurringAppointment` projections with existing `Appointment` docs) should filter out any projected date whose `dateKey` is in `cancelledDates`.

**Rationale:** The ghost card is computed client-side from the `RecurringAppointment` entity. Adding a `cancelledDates` field to the entity and checking it during projection is a minimal, local change.

## Risks / Trade-offs

- **Array grows over time** → Mitigation: limit `cancelledDates` to future dates only (prune entries older than today on read or via a periodic cleanup). This is a nice-to-have; for v1, unbounded growth is acceptable given low cardinality.
- **Race condition: cron runs between client `arrayUnion` and appointment deletion** → Mitigation: The existing idempotency check in the cron means the appointment would be created again only if the batch deletion succeeds but `cancelledDates` write fails, which is atomically impossible (same batch). If the batch fails entirely, nothing changes.
- **Client-side batch does not cover ledger entries in sub-collections** → Mitigation: The ledger entry (if any) is identified by `appointmentId`; include it explicitly in the batch delete. If not found, skip gracefully.

## Migration Plan

1. Deploy Firestore rules update (allow `cancelledDates` arrayUnion for provider owner).
2. Deploy updated `dailyRecurringProcessor` with the skip logic (backward-compatible — `cancelledDates` defaults to `[]`).
3. Ship Flutter app update with domain change + UI action.
4. No data backfill needed — existing docs without `cancelledDates` behave identically.

## Open Questions

- Should cancelled occurrences show a visual indicator on the timeline (e.g. a greyed-out "Cancelado" chip) or simply disappear? **Default: simply disappear** — the professional initiated the cancellation and doesn't need a reminder. Can revisit if UX testing suggests otherwise.
