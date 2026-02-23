import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/use_cases/sign_in_with_email_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmailUseCase(mockRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  final tProvider = Provider(
    id: 'test_id',
    email: tEmail,
    name: 'Test Name',
    subscriptionStatus: SubscriptionStatus.active,
    createdAt: DateTime.now(),
  );

  test('should return Provider when sign in is successful', () async {
    // arrange
    when(
      () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
    ).thenAnswer((_) async => Right(tProvider));

    // act
    final result = await useCase.call(tEmail, tPassword);

    // assert
    expect(result, Right(tProvider));
    verify(
      () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when sign in fails', () async {
    // arrange
    const tFailure = Failure.invalidCredentials();
    when(
      () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
    ).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await useCase.call(tEmail, tPassword);

    // assert
    expect(result, const Left(tFailure));
    verify(
      () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
