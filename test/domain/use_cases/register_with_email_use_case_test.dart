import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/use_cases/register_with_email_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterWithEmailUseCase(mockRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tName = 'John Doe';
  final tProvider = Provider(
    id: 'test_id',
    email: tEmail,
    name: tName,
    subscriptionStatus: SubscriptionStatus.active,
    createdAt: DateTime.now(),
  );

  test('should return Provider when registration is successful', () async {
    // arrange
    when(
      () =>
          mockRepository.registerWithEmailAndPassword(tEmail, tPassword, tName),
    ).thenAnswer((_) async => Right(tProvider));

    // act
    final result = await useCase.call(tEmail, tPassword, tName);

    // assert
    expect(result, Right(tProvider));
    verify(
      () =>
          mockRepository.registerWithEmailAndPassword(tEmail, tPassword, tName),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when registration fails', () async {
    // arrange
    const tFailure = Failure.emailAlreadyInUse();
    when(
      () =>
          mockRepository.registerWithEmailAndPassword(tEmail, tPassword, tName),
    ).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await useCase.call(tEmail, tPassword, tName);

    // assert
    expect(result, const Left(tFailure));
    verify(
      () =>
          mockRepository.registerWithEmailAndPassword(tEmail, tPassword, tName),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
