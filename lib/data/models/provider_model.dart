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
  final DateTime? subscriptionExpiresAt;
  final double defaultMonthlyInterestRate;
  final DateTime createdAt;

  const ProviderModel({
    required this.id,
    required this.email,
    required this.name,
    required this.subscriptionStatus,
    this.subscriptionExpiresAt,
    required this.defaultMonthlyInterestRate,
    required this.createdAt,
  });

  /// Creates a [ProviderModel] from a Firebase Auth user's basic info.
  ///
  /// New users get [SubscriptionStatus.active] by default.
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
      defaultMonthlyInterestRate: 0.0,
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
      if (subscriptionExpiresAt != null)
        'subscriptionExpiresAt': Timestamp.fromDate(subscriptionExpiresAt!),
      'defaultMonthlyInterestRate': defaultMonthlyInterestRate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a [ProviderModel] from a Firestore document map.
  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      subscriptionStatus: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['subscriptionStatus'],
        orElse: () => SubscriptionStatus.active,
      ),
      subscriptionExpiresAt:
          json['subscriptionExpiresAt'] != null
              ? (json['subscriptionExpiresAt'] as Timestamp).toDate()
              : null,
      defaultMonthlyInterestRate:
          (json['defaultMonthlyInterestRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Maps this model to the pure domain [Provider] entity.
  Provider toEntity() {
    return Provider(
      id: id,
      email: email,
      name: name,
      subscriptionStatus: subscriptionStatus,
      subscriptionExpiresAt: subscriptionExpiresAt,
      defaultMonthlyInterestRate: defaultMonthlyInterestRate,
      createdAt: createdAt,
    );
  }
}
