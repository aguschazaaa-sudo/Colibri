import 'package:freezed_annotation/freezed_annotation.dart';

part 'provider.freezed.dart';

enum SubscriptionStatus { active, pastDue, suspended }

enum SubscriptionPlan { none, basic, premium }

@freezed
abstract class Provider with _$Provider {
  const Provider._();

  const factory Provider({
    required String id,
    required String email,
    required String name,
    required SubscriptionStatus subscriptionStatus,
    @Default(SubscriptionPlan.none) SubscriptionPlan plan,
    DateTime? subscriptionExpiresAt,
    @Default(0.0) double defaultMonthlyInterestRate,
    String? whatsappTemplate,
    @Default(<String>[]) List<String> nonWorkingDays,
    required DateTime createdAt,
  }) = _Provider;

  bool get hasActivePlan =>
      subscriptionStatus == SubscriptionStatus.active &&
      plan != SubscriptionPlan.none;

  bool get canCreateAppointments => hasActivePlan;
}
