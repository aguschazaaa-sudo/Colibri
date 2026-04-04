import 'package:cobrador/domain/cancel_recurring_occurrence_use_case.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/ledger_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLedgerRepository extends Mock implements LedgerRepository {}

void main() {
  late MockLedgerRepository mockRepo;
  late CancelRecurringOccurrenceUseCase useCase;

  setUp(() {
    mockRepo = MockLedgerRepository();
    useCase = CancelRecurringOccurrenceUseCase(mockRepo);
  });

  const providerId = 'prov1';
  const patientId = 'pat1';
  const recurringId = 'rec1';
  const dateKey = '2026-04-10';

  group('CancelRecurringOccurrenceUseCase', () {
    test('happy path — ghost cancel (no existingAppointmentId) returns Right', () async {
      when(
        () => mockRepo.cancelOccurrence(
          providerId: providerId,
          patientId: patientId,
          recurringAppointmentId: recurringId,
          dateKey: dateKey,
          existingAppointmentId: null,
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepo.cancelOccurrence(
          providerId: providerId,
          patientId: patientId,
          recurringAppointmentId: recurringId,
          dateKey: dateKey,
          existingAppointmentId: null,
        ),
      ).called(1);
    });

    test('happy path — real appointment cancel (with existingAppointmentId) returns Right', () async {
      const appointmentId = 'apt1';

      when(
        () => mockRepo.cancelOccurrence(
          providerId: providerId,
          patientId: patientId,
          recurringAppointmentId: recurringId,
          dateKey: dateKey,
          existingAppointmentId: appointmentId,
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
        existingAppointmentId: appointmentId,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepo.cancelOccurrence(
          providerId: providerId,
          patientId: patientId,
          recurringAppointmentId: recurringId,
          dateKey: dateKey,
          existingAppointmentId: appointmentId,
        ),
      ).called(1);
    });

    test('idempotent — calling twice delegates both calls to repo', () async {
      when(
        () => mockRepo.cancelOccurrence(
          providerId: any(named: 'providerId'),
          patientId: any(named: 'patientId'),
          recurringAppointmentId: any(named: 'recurringAppointmentId'),
          dateKey: any(named: 'dateKey'),
          existingAppointmentId: any(named: 'existingAppointmentId'),
        ),
      ).thenAnswer((_) async => const Right(null));

      await useCase(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
      );
      await useCase(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
      );

      verify(
        () => mockRepo.cancelOccurrence(
          providerId: any(named: 'providerId'),
          patientId: any(named: 'patientId'),
          recurringAppointmentId: any(named: 'recurringAppointmentId'),
          dateKey: any(named: 'dateKey'),
          existingAppointmentId: any(named: 'existingAppointmentId'),
        ),
      ).called(2);
    });

    test('returns Left when repo fails', () async {
      when(
        () => mockRepo.cancelOccurrence(
          providerId: any(named: 'providerId'),
          patientId: any(named: 'patientId'),
          recurringAppointmentId: any(named: 'recurringAppointmentId'),
          dateKey: any(named: 'dateKey'),
          existingAppointmentId: any(named: 'existingAppointmentId'),
        ),
      ).thenAnswer(
        (_) async => const Left(Failure.serverError('permission-denied')),
      );

      final result = await useCase(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
