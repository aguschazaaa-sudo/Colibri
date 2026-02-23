import 'package:fpdart/fpdart.dart';
import '../auth_repository.dart';
import '../failure.dart';

/// Sends a password-reset email to the given address.
class SendPasswordResetUseCase {
  final AuthRepository _repository;

  const SendPasswordResetUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
