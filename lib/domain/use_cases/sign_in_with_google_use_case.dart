import 'package:fpdart/fpdart.dart';
import '../auth_repository.dart';
import '../failure.dart';
import '../provider.dart';

/// Signs in a user with their Google account.
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  const SignInWithGoogleUseCase(this._repository);

  Future<Either<Failure, Provider>> call() {
    return _repository.signInWithGoogle();
  }
}
