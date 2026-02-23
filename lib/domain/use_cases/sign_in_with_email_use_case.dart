import 'package:fpdart/fpdart.dart';
import '../auth_repository.dart';
import '../failure.dart';
import '../provider.dart';

/// Signs in a user with email and password.
class SignInWithEmailUseCase {
  final AuthRepository _repository;

  const SignInWithEmailUseCase(this._repository);

  Future<Either<Failure, Provider>> call(String email, String password) {
    return _repository.signInWithEmailAndPassword(email, password);
  }
}
