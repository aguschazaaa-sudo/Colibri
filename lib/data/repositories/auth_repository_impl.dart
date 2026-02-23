import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/data/datasources/firebase_auth_data_source.dart';

/// Concrete implementation of [AuthRepository] backed by Firebase.
///
/// Delegates all operations to [FirebaseAuthDataSource] and maps
/// data models to domain entities.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Stream<Provider?> get authStateChanges {
    return _dataSource.authStateChanges.map((model) => model?.toEntity());
  }

  @override
  Provider? get currentUser => _dataSource.currentUser?.toEntity();

  @override
  Future<Either<Failure, Provider>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final result = await _dataSource.signInWithEmailAndPassword(
      email,
      password,
    );
    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, Provider>> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    final result = await _dataSource.registerWithEmailAndPassword(
      email,
      password,
      name,
    );
    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, Provider>> signInWithGoogle() async {
    final result = await _dataSource.signInWithGoogle();
    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) {
    return _dataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
