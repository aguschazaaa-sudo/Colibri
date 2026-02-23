import '../auth_repository.dart';

/// Signs out the current user.
class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  Future<void> call() {
    return _repository.signOut();
  }
}
