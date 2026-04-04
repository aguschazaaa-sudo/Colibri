## 1. Domain Layer

- [x] 1.1 Add `cancelledDates: List<String>` field to `RecurringAppointment` freezed entity (default `[]`)
- [x] 1.2 Run `build_runner` to regenerate `recurring_appointment.freezed.dart`
- [x] 1.3 Add abstract method `cancelOccurrence(String recurringAppointmentId, String patientId, String dateKey, String? existingAppointmentId)` to the recurring appointment repository contract

## 2. Data Layer

- [x] 2.1 Add `cancelledDates` field to `RecurringAppointmentModel.fromJson` and `toJson`
- [x] 2.2 Add `cancelledDates` to `RecurringAppointmentModel.fromEntity` and `toMap`
- [x] 2.3 Implement `cancelOccurrence` in `RecurringAppointmentRepositoryImpl` using a Firestore `WriteBatch`: `arrayUnion` the `dateKey` on the recurring doc, and if `existingAppointmentId` is provided, delete the appointment doc and its ledger entry within the same batch

## 3. Cloud Function

- [x] 3.1 In `dailyRecurringProcessor` (`processRecurringForTargetDate`), after the schedule check and before the idempotency check, add skip logic: if `(data.cancelledDates ?? []).includes(targetDateKey)`, update `lastGeneratedDate` and `continue`
- [x] 3.2 Add a log line for the skip: `${logPrefix} Skipping recurring ${recurringDoc.id} on ${targetDateKey} — cancelled by provider.`

## 4. Firestore Rules

- [x] 4.1 Update `firebase/firestore.rules` to allow the provider owner to perform `arrayUnion` on `cancelledDates` for their own `recurring_appointments` documents

## 5. Presentation — Use Case & Provider

- [x] 5.1 Create `CancelRecurringOccurrenceUseCase` in `lib/domain/` that wraps the repository method
- [x] 5.2 Create or extend a Riverpod `AsyncNotifier` to expose `cancelOccurrence(recurringAppointmentId, patientId, dateKey, existingAppointmentId?)` and surface loading/error state

## 6. Presentation — Timeline UI

- [x] 6.1 In the ghost-card projection logic (Riverpod provider that merges recurring rules with appointments), filter out projected dates whose `dateKey` is in `cancelledDates`
- [x] 6.2 Add a trash icon button (`Icons.delete_outline_rounded`) to the top-right corner of `ProjectedAppointmentCard` (ghost card); always visible since ghost cards are always recurring
- [x] 6.3 Add a trash icon button to the top-right corner of `TodayAppointmentCard` in timeline mode, rendered only when `appointment.recurringAppointmentId != null`
- [x] 6.4 Implement confirmation dialog before calling the use case
- [x] 6.5 Show success `SnackBar` on completion; show error `SnackBar` on failure with retry option

## 7. Tests

- [x] 7.1 Unit test `CancelRecurringOccurrenceUseCase`: happy path (ghost cancel), happy path (real appointment cancel), idempotent cancel
- [x] 7.2 Unit test `RecurringAppointmentRepositoryImpl.cancelOccurrence`: batch writes correct docs, handles missing appointment gracefully
- [x] 7.3 Unit test `processRecurringForTargetDate`: skips creation when `cancelledDates` includes target, generates normally when not in list, handles missing `cancelledDates` field
- [x] 7.4 Widget test: ghost card shows trash button; non-recurring appointment card hides trash button; confirmation dialog appears on trash button tap

## 8. Deploy

- [ ] 8.1 Run Security Guardian before deploy
- [ ] 8.2 Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] 8.3 Deploy updated Cloud Function: `firebase deploy --only functions:dailyRecurringProcessor`
- [ ] 8.4 Ship Flutter app update
