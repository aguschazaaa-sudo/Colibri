import 'package:freezed_annotation/freezed_annotation.dart';

part 'provider.freezed.dart';

enum SubscriptionStatus { active, pastDue, suspended }

@freezed
abstract class Provider with _$Provider {
  const Provider._();

  const factory Provider({
    required String id,
    required String email,
    required String name,
    required SubscriptionStatus subscriptionStatus,
    DateTime? subscriptionExpiresAt,
    @Default(0.0) double defaultMonthlyInterestRate,
    String? whatsappTemplate,
    required DateTime createdAt,
  }) = _Provider;

  bool get canCreateAppointments =>
      subscriptionStatus != SubscriptionStatus.suspended;
}
