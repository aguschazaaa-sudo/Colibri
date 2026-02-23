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

void main() {
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
    test('initial state is AsyncData(null)', () {
      final state = container.read(authNotifierProvider);
      expect(state, const AsyncData(null));
    });

    test('login success sets data', () async {
      // arrange
      const tEmail = 'test@example.com';
      const tPassword = 'password123';

      when(
        () => mockRepository.signInWithEmailAndPassword(tEmail, tPassword),
      ).thenAnswer((_) async => Right(tProvider));

      final listener = Listener<AsyncValue<void>>();
      container.listen(
        authNotifierProvider,
        listener.call,
        fireImmediately: true,
      );

      // act
      final result = await container
          .read(authNotifierProvider.notifier)
          .login(tEmail, tPassword);

      // assert
      expect(result.isRight(), true);
      verifyInOrder([
        () => listener(null, const AsyncData<void>(null)),
        () => listener(const AsyncData<void>(null), const AsyncLoading<void>()),
        () => listener(const AsyncLoading<void>(), const AsyncData<void>(null)),
      ]);
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

      final listener = Listener<AsyncValue<void>>();
      container.listen(
        authNotifierProvider,
        listener.call,
        fireImmediately: true,
      );

      // act
      final result = await container
          .read(authNotifierProvider.notifier)
          .login(tEmail, tPassword);

      // assert
      expect(result, const Left(tFailure));
      // In our design, we return the failure but keep the state as AsyncData to allow the UI to handle the error snippet.
      // The state transitions are AsyncData -> AsyncLoading -> AsyncData
      verifyInOrder([
        () => listener(null, const AsyncData<void>(null)),
        () => listener(const AsyncData<void>(null), const AsyncLoading<void>()),
        () => listener(const AsyncLoading<void>(), const AsyncData<void>(null)),
      ]);
    });
  });
}
