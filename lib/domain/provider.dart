import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cobrador/domain/vacation_period.dart';

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
    String? mpPreapprovalId,
    @Default(0.0) double defaultMonthlyInterestRate,
    @Default(0.0) double discountPercentage,
    String? whatsappTemplate,
    String? profession,
    @Default(<String>[]) List<String> nonWorkingDays,
    @Default(<VacationPeriod>[]) List<VacationPeriod> vacations,
    @Default(45) int defaultSessionDurationMinutes,
    required DateTime createdAt,
  }) = _Provider;

  bool get hasActivePlan {
    if (plan == SubscriptionPlan.none) return false;
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  bool get isTrial => mpPreapprovalId == null || mpPreapprovalId!.isEmpty;

  bool get canCreateAppointments => hasActivePlan;
}
