import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/use_cases/sign_out_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockRepository);
  });

  test('should call signOut on repository', () async {
    // arrange
    when(() => mockRepository.signOut()).thenAnswer((_) async => {});

    // act
    await useCase.call();

    // assert
    verify(() => mockRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
