import 'package:fpdart/fpdart.dart';
import 'failure.dart';
import 'provider.dart';

/// Contract for authentication operations.
///
/// Implementations live in the Data layer.
abstract class AuthRepository {
  /// Stream of auth state changes.
  /// Emits the current [Provider] or `null` when signed out.
  Stream<Provider?> get authStateChanges;

  /// The currently signed-in user, or `null`.
  Provider? get currentUser;

  /// Sign in with email and password.
  Future<Either<Failure, Provider>> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Register a new account with email, password and display name.
  Future<Either<Failure, Provider>> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  );

  /// Sign in with Google.
  Future<Either<Failure, Provider>> signInWithGoogle();

  /// Send a password-reset email.
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Sign out the current user.
  Future<void> signOut();
}
