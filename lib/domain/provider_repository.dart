import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:fpdart/fpdart.dart';

abstract class ProviderRepository {
  /// Watches the current provider document in Firestore for
  /// real-time subscription status or profile changes.
  Stream<Provider?> watchProvider(String providerId);

  /// Updates the provider's profile (name, default monthly interest rate)
  Future<Either<Failure, Provider>> updateProviderProfile(Provider provider);
}
