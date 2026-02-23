import 'package:fpdart/fpdart.dart';
import '../auth_repository.dart';
import '../failure.dart';
import '../provider.dart';

/// Registers a new user with email, password and display name.
class RegisterWithEmailUseCase {
  final AuthRepository _repository;

  const RegisterWithEmailUseCase(this._repository);

  Future<Either<Failure, Provider>> call(
    String email,
    String password,
    String name,
  ) {
    return _repository.registerWithEmailAndPassword(email, password, name);
  }
}
