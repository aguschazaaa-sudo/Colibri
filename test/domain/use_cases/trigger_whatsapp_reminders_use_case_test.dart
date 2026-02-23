import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/domain/communication_log_repository.dart';
import 'package:cobrador/domain/use_cases/trigger_whatsapp_reminders_use_case.dart';

class MockCommunicationLogRepository extends Mock
    implements CommunicationLogRepository {}

void main() {
  late TriggerWhatsAppRemindersUseCase useCase;
  late MockCommunicationLogRepository mockRepository;

  setUp(() {
    mockRepository = MockCommunicationLogRepository();
    useCase = TriggerWhatsAppRemindersUseCase(mockRepository);
  });

  final tPatientNoDebt = Patient(
    id: 'p1',
    providerId: 'prov1',
    name: 'John Doe',
    phoneNumber: '12345678',
    totalDebt: 0.0,
    createdAt: DateTime.now(),
  );

  final tPatientWithDebt = Patient(
    id: 'p2',
    providerId: 'prov1',
    name: 'Jane Doe',
    phoneNumber: '87654321',
    totalDebt: 500.0,
    createdAt: DateTime.now(),
  );

  final tLog = CommunicationLog(
    id: 'msg1',
    patientId: 'p2',
    providerId: 'prov1',
    messageId: '',
    sentAt: DateTime.now(),
    status: 'pending',
    totalDebtAtThatTime: 500.0,
  );

  group('TriggerWhatsAppRemindersUseCase', () {
    test('should return Failure when patient has no debt', () async {
      final result = await useCase.execute(tPatientNoDebt);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          l,
          const Failure.validationError(
            'El paciente no tiene deuda pendiente.',
          ),
        ),
        (r) => fail('Should not succeed'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should enqueue reminder when patient has debt > 0', () async {
      when(
        () => mockRepository.enqueueWhatsAppReminder(
          providerId: 'prov1',
          patientId: 'p2',
          totalDebtAtThatTime: 500.0,
        ),
      ).thenAnswer((_) async => Right(tLog));

      final result = await useCase.execute(tPatientWithDebt);

      expect(result, Right(tLog));
      verify(
        () => mockRepository.enqueueWhatsAppReminder(
          providerId: 'prov1',
          patientId: 'p2',
          totalDebtAtThatTime: 500.0,
        ),
      ).called(1);
    });
  });
}
