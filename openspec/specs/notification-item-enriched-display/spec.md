## ADDED Requirements

### Requirement: Notification item shows type label and content snippet
Each item in the communication history list SHALL display a human-readable notification type label and a brief content snippet derived from the `messageType` and `variables` fields already stored in Firestore.

- For `messageType == "appointment_reminder"`: type label is "Recordatorio de turno"; snippet shows date and time from `variables.fecha_turno` and `variables.hora_turno`.
- For `messageType == "payment_reminder"`: type label is "Aviso de deuda"; snippet shows the formatted `totalDebtAtThatTime` amount.
- When `messageType` is absent (legacy documents): show fallback label "Recordatorio" with no snippet.

#### Scenario: Appointment reminder item shows date and time
- **WHEN** a `CommunicationLog` with `messageType == "appointment_reminder"` is rendered
- **THEN** the item displays the label "Recordatorio de turno" and the snippet "28/03 a las 10:00 hs." (using values from `variables.fecha_turno` and `variables.hora_turno`)

#### Scenario: Payment reminder item shows debt amount
- **WHEN** a `CommunicationLog` with `messageType == "payment_reminder"` is rendered
- **THEN** the item displays the label "Aviso de deuda" and the formatted debt amount from `totalDebtAtThatTime`

#### Scenario: Legacy document without messageType shows fallback
- **WHEN** a `CommunicationLog` with no `messageType` is rendered
- **THEN** the item displays "Recordatorio" with no content snippet, without crashing

### Requirement: CommunicationLog entity exposes messageType and variables
The `CommunicationLog` domain entity SHALL include optional fields `messageType` (String?) and `variables` (Map<String, String>?) read from the Firestore document.

#### Scenario: Model reads messageType from Firestore
- **WHEN** a Firestore communications document containing `messageType: "appointment_reminder"` is mapped
- **THEN** the resulting `CommunicationLog` entity has `messageType == "appointment_reminder"`

#### Scenario: Model handles missing messageType gracefully
- **WHEN** a Firestore communications document without `messageType` is mapped
- **THEN** the resulting `CommunicationLog` entity has `messageType == null` and does not throw

### Requirement: Monthly stats counter shows only successful sends
The "Total del Mes" stat card on the Reminders page SHALL count only communication logs with `status == "sent"` for the current calendar month.

#### Scenario: Counter excludes failed and aborted notifications
- **WHEN** the current month has 5 logs: 3 with status "sent", 1 with "failed", 1 with "aborted"
- **THEN** the stat card displays 3

#### Scenario: Counter excludes pending notifications
- **WHEN** a communication log with status "pending" exists in the current month
- **THEN** it is NOT counted in the "Total del Mes" stat card
