import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart' as domain;
import 'package:cobrador/providers/auth_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

// ignore: subtype_of_sealed_class
class AsyncValueFake<T> extends Fake implements AsyncValue<T> {}

void main() {
  setUpAll(() {
    registerFallbackValue(AsyncValueFake<void>());
  });

  late ProviderContainer container;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    // Default mock behavior for auth state stream
    when(
      () => mockRepository.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));

    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  final tProvider = domain.Provider(
    id: 'test_id',
    email: 'test@example.com',
    name: 'Test Name',
    subscriptionStatus: domain.SubscriptionStatus.active,
    createdAt: DateTime.now(),
  );

  group('AuthNotifier', () {
    test('initial state is AsyncLoading() due to async build', () {
      final state = container.read(authNotifierProvider);
      expect(state, isA<AsyncLoading<void>>());
    });

    test('login success sets data', () async {
      // arrange
      const tEmail = 'test@example.com';
      const tPassword = 'password123';

      when(
        () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
      ).thenAnswer((_) async => Right(tProvider));

      // act
      final result = await container
          .read(authNotifierProvider.notifier)
          .login(tEmail, tPassword);

      // assert
      expect(result.isRight(), true);
      verify(
        () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
      ).called(1);
    });

    test('login failure sets data and returns failure', () async {
      // arrange
      const tEmail = 'test@example.com';
      const tPassword = 'password123';
      const tFailure = Failure.invalidCredentials();

      when(
        () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await container
          .read(authNotifierProvider.notifier)
          .login(tEmail, tPassword);

      // assert
      expect(result, const Left(tFailure));
    });
  });
}
