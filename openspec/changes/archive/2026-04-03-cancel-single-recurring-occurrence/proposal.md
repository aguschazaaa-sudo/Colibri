## Why

When a patient cancels a single session, the professional has no way to remove just that occurrence from the schedule without deactivating the entire recurring rule. This blocks the time slot on the agenda and may generate an unwanted debt entry, requiring manual workarounds.

## What Changes

- Add a `cancelledDates: string[]` field (list of `dateKey` strings, e.g. `"2026-04-10"`) to `RecurringAppointment` in both Domain and Data layers.
- Extend the daily cron (`dailyRecurringProcessor`) to skip generating appointments for dates present in `cancelledDates`.
- If the appointment was already generated (appointments are created 2 days ahead), cancelling an occurrence must also delete the appointment doc and its associated ledger entry.
- Add a "Cancelar esta sesión" action on the timeline — available on both the ghost card (not yet generated) and the real appointment card (already generated) when `recurringAppointmentId` is set.
- The cancelled occurrence is an exception: all other future occurrences continue to generate normally.

## Capabilities

### New Capabilities

- `recurring-occurrence-cancellation`: Allows the professional to cancel a single occurrence of a recurring appointment rule. Stores the exception as a `dateKey` in the recurring rule's `cancelledDates` list, prevents cron generation for that date, and removes any already-generated appointment + ledger entry for that occurrence.

### Modified Capabilities

- `day-timeline-view`: Ghost cards for projected recurring occurrences must now suppress for dates present in `cancelledDates` (i.e. no ghost card shown for a cancelled occurrence).

## Impact

- **Domain:** `RecurringAppointment` entity — add `cancelledDates` field.
- **Data:** `RecurringAppointmentModel` Freezed model, Firestore read/write.
- **Cloud Function:** `dailyRecurringProcessor` — skip logic for cancelled dates.
- **Cloud Function:** New callable or Firestore write path to add a `dateKey` to `cancelledDates` and optionally delete the appointment + ledger doc.
- **Presentation:** Timeline card (ghost + real) action menu; Riverpod use case / provider.
- **Firestore Rules:** Write access to `cancelledDates` field on `recurring_appointments`.
