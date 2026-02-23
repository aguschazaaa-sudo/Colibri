import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/use_cases/sign_in_with_google_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithGoogleUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithGoogleUseCase(mockRepository);
  });

  final tProvider = Provider(
    id: 'test_id',
    email: 'test@example.com',
    name: 'Test Name',
    subscriptionStatus: SubscriptionStatus.active,
    createdAt: DateTime.now(),
  );

  test('should return Provider when google sign in is successful', () async {
    // arrange
    when(
      () => mockRepository.signInWithGoogle(),
    ).thenAnswer((_) async => Right(tProvider));

    // act
    final result = await useCase.call();

    // assert
    expect(result, Right(tProvider));
    verify(() => mockRepository.signInWithGoogle()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when google sign in fails', () async {
    // arrange
    const tFailure = Failure.networkError();
    when(
      () => mockRepository.signInWithGoogle(),
    ).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await useCase.call();

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockRepository.signInWithGoogle()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
