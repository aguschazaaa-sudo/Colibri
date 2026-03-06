import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/provider.dart';

/// Data model for mapping Firebase User to domain Provider entity.
///
/// This class bridges the gap between Firebase Auth data and our
/// domain entity. No Firebase types leak past this boundary.
class ProviderModel {
  final String id;
  final String email;
  final String name;
  final SubscriptionStatus subscriptionStatus;
  final SubscriptionPlan plan;
  final DateTime? subscriptionExpiresAt;
  final double defaultMonthlyInterestRate;
  final List<String> nonWorkingDays;
  final DateTime createdAt;

  const ProviderModel({
    required this.id,
    required this.email,
    required this.name,
    required this.subscriptionStatus,
    required this.plan,
    this.subscriptionExpiresAt,
    required this.defaultMonthlyInterestRate,
    this.nonWorkingDays = const [],
    required this.createdAt,
  });

  /// Creates a [ProviderModel] from a Firebase Auth user's basic info.
  ///
  /// New users get a 5-day basic trial.
  factory ProviderModel.fromFirebaseUser({
    required String uid,
    required String? email,
    required String? displayName,
  }) {
    return ProviderModel(
      id: uid,
      email: email ?? '',
      name: displayName ?? '',
      subscriptionStatus: SubscriptionStatus.active,
      plan: SubscriptionPlan.basic,
      subscriptionExpiresAt: DateTime.now().add(const Duration(days: 5)),
      defaultMonthlyInterestRate: 0.0,
      nonWorkingDays: const [
        '01-01',
        '03-24',
        '04-02',
        '05-01',
        '05-25',
        '06-20',
        '07-09',
        '12-08',
        '12-25',
      ],
      createdAt: DateTime.now(),
    );
  }

  /// Converts to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'subscriptionStatus': subscriptionStatus.name,
      'plan': plan.name,
      if (subscriptionExpiresAt != null)
        'subscriptionExpiresAt': Timestamp.fromDate(subscriptionExpiresAt!),
      'defaultMonthlyInterestRate': defaultMonthlyInterestRate,
      'nonWorkingDays': nonWorkingDays,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [ProviderModel] from a Firestore document map.
  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: (json['id'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      subscriptionStatus: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['subscriptionStatus'],
        orElse: () => SubscriptionStatus.active,
      ),
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.none,
      ),
      subscriptionExpiresAt:
          json['subscriptionExpiresAt'] != null
              ? (json['subscriptionExpiresAt'] as Timestamp).toDate()
              : null,
      defaultMonthlyInterestRate:
          (json['defaultMonthlyInterestRate'] as num?)?.toDouble() ?? 0.0,
      nonWorkingDays:
          (json['nonWorkingDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  /// Maps this model to the pure domain [Provider] entity.
  Provider toEntity() {
    return Provider(
      id: id,
      email: email,
      name: name,
      subscriptionStatus: subscriptionStatus,
      plan: plan,
      subscriptionExpiresAt: subscriptionExpiresAt,
      defaultMonthlyInterestRate: defaultMonthlyInterestRate,
      nonWorkingDays: nonWorkingDays,
      createdAt: createdAt,
    );
  }
}
