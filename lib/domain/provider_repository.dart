import 'package:cobrador/domain/dashboard_report.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/subscription_pricing.dart';
import 'vacation_period.dart';
import 'package:fpdart/fpdart.dart';

abstract class ProviderRepository {
  /// Watches the current provider document in Firestore for
  /// real-time subscription status or profile changes.
  Stream<Provider?> watchProvider(String providerId);

  /// Updates the provider's profile (name, default monthly interest rate)
  Future<Either<Failure, Provider>> updateProviderProfile(Provider provider);

  /// Watches the pre-calculated dashboard metrics document stored at:
  /// `providers/{providerId}/metrics/dashboard`
  ///
  /// Emits [DashboardReport.empty()] if the document doesn't exist yet.
  Stream<DashboardReport> watchDashboardReport(String providerId);

  /// Adds a non-working day (MM-DD format) to the provider's list.
  Future<Either<Failure, Unit>> addNonWorkingDay(String providerId, String day);

  /// Removes a non-working day (MM-DD format) from the provider's list.
  Future<Either<Failure, Unit>> removeNonWorkingDay(
    String providerId,
    String day,
  );

  /// Adds a vacation period to the provider's list.
  Future<Either<Failure, Unit>> addVacationPeriod(
    String providerId,
    VacationPeriod period,
  );

  /// Removes a vacation period from the provider's list.
  Future<Either<Failure, Unit>> removeVacationPeriod(
    String providerId,
    VacationPeriod period,
  );

  /// Watches the global subscription pricing document in `metadata/pricing`.
  Stream<SubscriptionPricing> watchSubscriptionPricing();
}
