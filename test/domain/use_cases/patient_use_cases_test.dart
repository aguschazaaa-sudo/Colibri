import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/patient_repository.dart';
import 'package:cobrador/domain/use_cases/patient_use_cases.dart';

class MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  late CreatePatientUseCase createUseCase;
  late UpdatePatientUseCase updateUseCase;
  late MockPatientRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      Patient(
        id: 'fallback_id',
        providerId: 'fallback_provider',
        name: 'Fallback',
        phoneNumber: '12345678',
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockPatientRepository();
    createUseCase = CreatePatientUseCase(mockRepository);
    updateUseCase = UpdatePatientUseCase(mockRepository);
  });

  final tDate = DateTime(2023, 1, 1);
  final tPatient = Patient(
    id: 'p1',
    providerId: 'prov1',
    name: 'John Doe',
    phoneNumber: '+5491112345678',
    createdAt: tDate,
  );

  group('CreatePatientUseCase', () {
    test('should return Failure when name is empty', () async {
      final invalidPatient = tPatient.copyWith(name: '   ');

      final result = await createUseCase.execute(invalidPatient);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          l,
          const Failure.validationError(
            'El nombre del paciente no puede estar vacío.',
          ),
        ),
        (r) => fail('Should not succeed'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test(
      'should return Failure when phoneNumber is less than 8 characters',
      () async {
        final invalidPatient = tPatient.copyWith(phoneNumber: '1234567');

        final result = await createUseCase.execute(invalidPatient);

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(
            l,
            const Failure.validationError(
              'El teléfono debe tener un formato válido (mínimo 8 caracteres).',
            ),
          ),
          (r) => fail('Should not succeed'),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should call repository.createPatient and return Patient on valid data',
      () async {
        when(
          () => mockRepository.createPatient(any()),
        ).thenAnswer((_) async => Right(tPatient));

        final result = await createUseCase.execute(tPatient);

        expect(result, Right(tPatient));
        verify(() => mockRepository.createPatient(tPatient)).called(1);
      },
    );
  });

  group('UpdatePatientUseCase', () {
    test('should return Failure when name is empty', () async {
      final invalidPatient = tPatient.copyWith(name: '');

      final result = await updateUseCase.execute(invalidPatient);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          l,
          const Failure.validationError(
            'El nombre del paciente no puede estar vacío.',
          ),
        ),
        (r) => fail('Should not succeed'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('should return Failure when phoneNumber is invalid', () async {
      final invalidPatient = tPatient.copyWith(phoneNumber: 'abc');

      final result = await updateUseCase.execute(invalidPatient);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          l,
          const Failure.validationError(
            'El teléfono debe tener un formato válido (mínimo 8 caracteres).',
          ),
        ),
        (r) => fail('Should not succeed'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test(
      'should call repository.updatePatient and return Patient on valid data',
      () async {
        when(
          () => mockRepository.updatePatient(any()),
        ).thenAnswer((_) async => Right(tPatient));

        final result = await updateUseCase.execute(tPatient);

        expect(result, Right(tPatient));
        verify(() => mockRepository.updatePatient(tPatient)).called(1);
      },
    );
  });
}
