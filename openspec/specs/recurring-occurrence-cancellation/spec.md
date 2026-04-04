### Requirement: Professional can cancel a single recurring occurrence
The system SHALL allow a professional to cancel one specific occurrence of an active `RecurringAppointment` rule without deactivating the rule or affecting other future occurrences. The cancellation SHALL be persisted by adding the target `dateKey` to the `cancelledDates` array on the `RecurringAppointment` document.

#### Scenario: Cancel a not-yet-generated occurrence
- **WHEN** the professional selects "Cancelar esta sesión" on a ghost card for a date that has no real `Appointment` yet
- **THEN** the `dateKey` is added to `cancelledDates` on the `RecurringAppointment` doc, the ghost card disappears from the timeline, and all other future occurrences remain unaffected

#### Scenario: Cancel an already-generated occurrence
- **WHEN** the professional selects "Cancelar esta sesión" on a real `Appointment` card that has a non-null `recurringAppointmentId`
- **THEN** the `dateKey` is added to `cancelledDates` on the `RecurringAppointment` doc AND the `Appointment` document is deleted AND its associated ledger entry (if any) is deleted — all in a single atomic Firestore batch

#### Scenario: Duplicate cancellation is idempotent
- **WHEN** the professional attempts to cancel an occurrence whose `dateKey` is already present in `cancelledDates`
- **THEN** no error is raised and the system state remains unchanged (Firestore `arrayUnion` guarantees idempotency)

### Requirement: Cron skips cancelled occurrence dates
The `dailyRecurringProcessor` Cloud Function SHALL NOT generate an `Appointment` for a target date whose `dateKey` is present in the `RecurringAppointment`'s `cancelledDates` array. It SHALL still update `lastGeneratedDate` for that date so the schedule advances normally.

#### Scenario: Cron encounters a cancelled date
- **WHEN** `dailyRecurringProcessor` evaluates a `RecurringAppointment` whose `cancelledDates` contains the current `targetDateKey`
- **THEN** no `Appointment` document is created, `lastGeneratedDate` is updated to `targetDate`, and the function logs the skip

#### Scenario: Cron generates normally for non-cancelled dates
- **WHEN** `dailyRecurringProcessor` evaluates a `RecurringAppointment` with a `cancelledDates` list that does NOT contain the current `targetDateKey`
- **THEN** the appointment is created as usual (existing behavior unchanged)

#### Scenario: Cron handles missing cancelledDates field
- **WHEN** a `RecurringAppointment` document has no `cancelledDates` field (legacy document)
- **THEN** the cron treats it as an empty array and generates the appointment normally

### Requirement: Cancel action is a visible trash icon button on recurring appointment cards
The timeline card for a recurring-linked appointment (ghost or real) SHALL render a trash icon button (`Icons.delete_outline_rounded`) in the top-right corner of the card. This button SHALL NOT appear on non-recurring appointments (appointments without `recurringAppointmentId`).

#### Scenario: Ghost card shows trash button
- **WHEN** a ghost card is rendered in the timeline for a `RecurringAppointment`
- **THEN** a trash icon button is visible in the top-right corner of the card

#### Scenario: Real recurring appointment card shows trash button
- **WHEN** an `Appointment` card with a non-null `recurringAppointmentId` is rendered in the timeline
- **THEN** a trash icon button is visible in the top-right corner of the card, alongside the existing "Cobrar total" action

#### Scenario: Non-recurring appointment card hides trash button
- **WHEN** an `Appointment` card with a null `recurringAppointmentId` is rendered in the timeline
- **THEN** no trash icon button is shown

### Requirement: Cancel action requires confirmation
The system SHALL display a confirmation dialog before executing the cancellation to prevent accidental taps.

#### Scenario: User confirms cancellation
- **WHEN** the professional taps "Cancelar esta sesión" and then confirms in the dialog
- **THEN** the cancellation is executed and a success SnackBar is shown

#### Scenario: User dismisses confirmation
- **WHEN** the professional taps "Cancelar esta sesión" and then dismisses the dialog
- **THEN** no changes are made and the timeline is unchanged
