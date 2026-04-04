## MODIFIED Requirements

### Requirement: Projected recurring appointments shown as ghost cards
Active `RecurringAppointment` rules that project a session on the selected day but do not yet have a matching `Appointment` (matched by `recurringAppointmentId`) SHALL be rendered as "ghost" cards with a distinct visual style (reduced opacity, dashed border, chip "Pendiente"), UNLESS the projected date's `dateKey` is present in the rule's `cancelledDates` array — in which case no card (ghost or real) SHALL be shown.

#### Scenario: Projected appointment renders with ghost style
- **WHEN** a `RecurringAppointment` projects a session on the selected day and no real `Appointment` exists with that `recurringAppointmentId`
- **THEN** a ghost card is shown at the projected time slot with the label "Pendiente de confirmar"

#### Scenario: Ghost card suppressed when real appointment exists
- **WHEN** a `RecurringAppointment` projects a session on the selected day AND a real `Appointment` with matching `recurringAppointmentId` exists for that day
- **THEN** only the real appointment card is shown (no ghost duplicate)

#### Scenario: Ghost card is non-interactive for payment
- **WHEN** the user taps the "Cobrar total" area of a ghost card
- **THEN** no payment action is triggered; the tap navigates to the patient detail or shows an informational snackbar

#### Scenario: Ghost card suppressed for cancelled occurrence
- **WHEN** a `RecurringAppointment` projects a session on the selected day AND the selected day's `dateKey` is present in `cancelledDates`
- **THEN** no card (ghost or real) is shown for that occurrence on the timeline
