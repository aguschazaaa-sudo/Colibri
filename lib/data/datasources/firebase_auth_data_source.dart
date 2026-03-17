import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/data/models/provider_model.dart';

/// Data source that interacts directly with Firebase Auth and Google Sign-In.
///
/// All Firebase types are consumed here and never leak to upper layers.
/// [FirebaseAuthException] errors are mapped to [Failure] objects.
class FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of auth state mapped to [ProviderModel].
  Stream<ProviderModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _fetchProviderFromFirestore(user);
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
      final model = await _fetchProviderFromFirestore(credential.user!);
      return Right(model);
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

      // Patch the Firestore doc with the correct name from the client.
      // We proactively provision the full default user model here to prevent
      // UI crashes before the cloud function finishes creating the doc.
      final modelToSet = ProviderModel.fromFirebaseUser(
        uid: updatedUser.uid,
        email: email,
        displayName: name,
      );

      await _firestore
          .collection('providers')
          .doc(updatedUser.uid)
          .set(modelToSet.toJson(), SetOptions(merge: true));

      final model = await _fetchProviderFromFirestore(updatedUser);
      return Right(model);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapAuthException(e));
    }
  }

  /// Sign in with Google.
  Future<Either<Failure, ProviderModel>> signInWithGoogle() async {
    try {
      firebase_auth.User? user;

      if (kIsWeb) {
        // En la web, usamos el proveedor nativo de Firebase Auth que no requiere configurar
        // explícitamente el Client ID como lo requiere el plugin google_sign_in.
        final googleProvider = firebase_auth.GoogleAuthProvider();
        final userCredential = await _firebaseAuth.signInWithPopup(
          googleProvider,
        );
        user = userCredential.user;
      } else {
        // En móvil/desktop, usamos el plugin google_sign_in
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          return const Left(Failure.unknown('Inicio con Google cancelado'));
        }

        final googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );
        user = userCredential.user;
      }

      if (user == null) {
        return const Left(
          Failure.unknown('No se pudo obtener el usuario de Firebase'),
        );
      }

      final model = await _fetchProviderFromFirestore(user);
      return Right(model);
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

  Future<ProviderModel> _fetchProviderFromFirestore(
    firebase_auth.User user,
  ) async {
    // Retry loop for when the CF is still creating the doc (especially on new sign-up)
    for (int i = 0; i < 4; i++) {
      try {
        final doc =
            await _firestore.collection('providers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure we merge the ID from the doc path, just in case
          data['id'] = doc.id;
          return ProviderModel.fromJson(data);
        }
      } catch (e) {
        // Ignore read errors during retry
      }
      // Wait before retrying (backoff)
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
    }

    // Fallback if cloud function failed entirely or is delayed too much
    return _userToModel(user);
  }

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
      case 'wrong-password':
        return const Failure.invalidCredentials();
      case 'user-not-found':
        return const Failure.notFound('No se encontró cuenta de usuario');
      case 'weak-password':
        return const Failure.weakPassword();
      case 'network-request-failed':
        return const Failure.networkError();
      default:
        return Failure.unknown(e.message ?? 'Unknown auth error');
    }
  }
}
