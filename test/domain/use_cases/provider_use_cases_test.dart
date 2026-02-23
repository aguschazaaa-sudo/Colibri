import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/provider_repository.dart';
import 'package:cobrador/domain/use_cases/provider_use_cases.dart';

class MockProviderRepository extends Mock implements ProviderRepository {}

void main() {
  late UpdateProviderProfileUseCase useCase;
  late MockProviderRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      Provider(
        id: 'fallback_id',
        email: 'fallback@example.com',
        name: 'Fallback Provider',
        subscriptionStatus: SubscriptionStatus.active,
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockProviderRepository();
    useCase = UpdateProviderProfileUseCase(mockRepository);
  });

  final tProvider = Provider(
    id: 'prov1',
    email: 'prov@example.com',
    name: 'Dr. House',
    subscriptionStatus: SubscriptionStatus.active,
    createdAt: DateTime(2023, 1, 1),
    whatsappTemplate:
        'Hola {{nombre_paciente}}, tienes una deuda de \${{monto_total}}.',
  );

  group('UpdateProviderProfileUseCase', () {
    test('should return Failure when name is empty', () async {
      final invalidProvider = tProvider.copyWith(name: '   ');

      final result = await useCase.execute(invalidProvider);

      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(
          l,
          const Failure.validationError(
            'El nombre del profesional no puede estar vacío.',
          ),
        ),
        (r) => fail('Should not succeed'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test(
      'should return Failure when whatsappTemplate is missing variables',
      () async {
        // Missing {{monto_total}}
        final invalidProvider = tProvider.copyWith(
          whatsappTemplate: 'Hola {{nombre_paciente}}, te recuerdo.',
        );

        final result = await useCase.execute(invalidProvider);

        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(
            l,
            const Failure.validationError(
              'La plantilla de WhatsApp debe incluir {{nombre_paciente}} y {{monto_total}}.',
            ),
          ),
          (r) => fail('Should not succeed'),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test(
      'should call repository.updateProviderProfile on valid data',
      () async {
        when(
          () => mockRepository.updateProviderProfile(any()),
        ).thenAnswer((_) async => Right(tProvider));

        final result = await useCase.execute(tProvider);

        expect(result, Right(tProvider));
        verify(() => mockRepository.updateProviderProfile(tProvider)).called(1);
      },
    );
  });
}
