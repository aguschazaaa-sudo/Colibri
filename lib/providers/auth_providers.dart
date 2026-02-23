import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart' as domain;
import 'package:cobrador/domain/use_cases/sign_in_with_email_use_case.dart';
import 'package:cobrador/domain/use_cases/register_with_email_use_case.dart';
import 'package:cobrador/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:cobrador/domain/use_cases/send_password_reset_use_case.dart';
import 'package:cobrador/domain/use_cases/sign_out_use_case.dart';
import 'package:cobrador/data/datasources/firebase_auth_data_source.dart';
import 'package:cobrador/data/repositories/auth_repository_impl.dart';

// ── Data Source ────────────────────────────────────────────────────────────

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>(
  (ref) => FirebaseAuthDataSource(),
);

// ── Repository ────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(firebaseAuthDataSourceProvider)),
);

// ── Use Cases ─────────────────────────────────────────────────────────────

final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>(
  (ref) => SignInWithEmailUseCase(ref.watch(authRepositoryProvider)),
);

final registerWithEmailUseCaseProvider = Provider<RegisterWithEmailUseCase>(
  (ref) => RegisterWithEmailUseCase(ref.watch(authRepositoryProvider)),
);

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final sendPasswordResetUseCaseProvider = Provider<SendPasswordResetUseCase>(
  (ref) => SendPasswordResetUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

// ── Auth State (stream) ───────────────────────────────────────────────────

/// Watches the Firebase auth state as a stream.
/// Used by GoRouter's redirect and to determine if user is logged in.
final authStateProvider = StreamProvider<domain.Provider?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── GoRouter refresh notifier ──────────────────────────────────────────────

/// Converts [authStateProvider] into a [Listenable] for GoRouter's
/// `refreshListenable`.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(Ref ref) {
    ref.listen<AsyncValue<domain.Provider?>>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

final authStateListenableProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier(ref);
});

// ── Auth Actions Notifier ──────────────────────────────────────────────────

/// Handles auth actions (login, register, etc.) and exposes loading/error
/// state via [AsyncValue].
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Either<Failure, domain.Provider>> login(
    String email,
    String password,
  ) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signInWithEmailUseCaseProvider)
        .call(email, password);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }

  Future<Either<Failure, domain.Provider>> register(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncLoading();
    final result = await ref
        .read(registerWithEmailUseCaseProvider)
        .call(email, password, name);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }

  Future<Either<Failure, domain.Provider>> googleSignIn() async {
    state = const AsyncLoading();
    final result = await ref.read(signInWithGoogleUseCaseProvider).call();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }

  Future<Either<Failure, Unit>> resetPassword(String email) async {
    state = const AsyncLoading();
    final result = await ref.read(sendPasswordResetUseCaseProvider).call(email);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }

  Future<void> logout() async {
    await ref.read(signOutUseCaseProvider).call();
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
