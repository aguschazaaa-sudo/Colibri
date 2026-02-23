import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/data/models/provider_model.dart';

/// Data source that interacts directly with Firebase Auth and Google Sign-In.
///
/// All Firebase types are consumed here and never leak to upper layers.
/// [FirebaseAuthException] errors are mapped to [Failure] objects.
class FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSource({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  /// Stream of auth state mapped to [ProviderModel].
  Stream<ProviderModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return ProviderModel.fromFirebaseUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    });
  }

  /// Currently signed-in user as [ProviderModel], or null.
  ProviderModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return ProviderModel.fromFirebaseUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  /// Sign in with email and password.
  Future<Either<Failure, ProviderModel>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(_userToModel(credential.user!));
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapAuthException(e));
    }
  }

  /// Register with email, password, and display name.
  Future<Either<Failure, ProviderModel>> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      await credential.user!.reload();
      final updatedUser = _firebaseAuth.currentUser!;
      return Right(_userToModel(updatedUser));
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapAuthException(e));
    }
  }

  /// Sign in with Google.
  Future<Either<Failure, ProviderModel>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return const Left(Failure.unknown('Google sign-in cancelled'));
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return Right(_userToModel(userCredential.user!));
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapAuthException(e));
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  /// Send password reset email.
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapAuthException(e));
    }
  }

  /// Sign out from Firebase (and clear Google session).
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Google sign-out may fail if not initialized; safe to ignore.
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  ProviderModel _userToModel(firebase_auth.User user) {
    return ProviderModel.fromFirebaseUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  Failure _mapAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const Failure.emailAlreadyInUse();
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return const Failure.invalidCredentials();
      case 'weak-password':
        return const Failure.weakPassword();
      case 'network-request-failed':
        return const Failure.networkError();
      default:
        return Failure.unknown(e.message ?? 'Unknown auth error');
    }
  }
}
