import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/use_cases/send_password_reset_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendPasswordResetUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendPasswordResetUseCase(mockRepository);
  });

  const tEmail = 'test@example.com';

  test('should return unit when reset email is sent successfully', () async {
    // arrange
    when(
      () => mockRepository.sendPasswordResetEmail(tEmail),
    ).thenAnswer((_) async => const Right(unit));

    // act
    final result = await useCase.call(tEmail);

    // assert
    expect(result, const Right(unit));
    verify(() => mockRepository.sendPasswordResetEmail(tEmail)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when sending reset email fails', () async {
    // arrange
    const tFailure = Failure.notFound('No account found');
    when(
      () => mockRepository.sendPasswordResetEmail(tEmail),
    ).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await useCase.call(tEmail);

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockRepository.sendPasswordResetEmail(tEmail)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
