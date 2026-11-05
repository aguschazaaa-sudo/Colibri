## 1. Domain — CommunicationLog entity

- [x] 1.1 Add `String? messageType` and `Map<String, String>? variables` fields to `CommunicationLog` Freezed entity in `lib/domain/communication_log.dart`
- [x] 1.2 Re-run `build_runner` to regenerate `communication_log.freezed.dart`

## 2. Data — CommunicationLogModel

- [x] 2.1 Add `messageType` and `variables` fields to `CommunicationLogModel` in `lib/data/models/communication_log_model.dart`
- [x] 2.2 Update `fromJson` to read `messageType` (nullable String) and `variables` (cast `Map<String, dynamic>` to `Map<String, String>`) from Firestore JSON
- [x] 2.3 Update `toEntity()` to pass the new fields to `CommunicationLog`

## 3. Presentation — Stats filter fix

- [x] 3.1 In `remindersStats` provider (`lib/presentation/providers/reminders_provider.dart`), add `.where((l) => l.status == 'sent')` to the `totalThisMonth` filter

## 4. Presentation — ReminderHistoryItem enriched display

- [x] 4.1 Add `_typeLabel` helper to `ReminderHistoryItem` that returns "Recordatorio de turno" for `appointment_reminder`, "Aviso de deuda" for `payment_reminder`, and "Recordatorio" as fallback
- [x] 4.2 Add `_contentSnippet` helper that returns the formatted snippet: for appointment reminders uses `variables['fecha_turno']` + `variables['hora_turno']`; for payment reminders formats `totalDebtAtThatTime` as currency; returns empty string when data is absent
- [x] 4.3 Update the `subtitle` of the `ListTile` to show the type label on the first line and the content snippet + relative time on the second line (or inline, whichever fits best)
