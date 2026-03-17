import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_pricing.freezed.dart';

@freezed
class PlanPricing with _$PlanPricing {
  const factory PlanPricing({
    required double priceUsd,
    required double exchangeRate,
    required double priceArs,
  }) = _PlanPricing;
}

@freezed
class SubscriptionPricing with _$SubscriptionPricing {
  const factory SubscriptionPricing({
    required PlanPricing basic,
    required PlanPricing premium,
    required DateTime lastUpdated,
  }) = _SubscriptionPricing;

  factory SubscriptionPricing.empty() => SubscriptionPricing(
    basic: const PlanPricing(priceUsd: 0, exchangeRate: 0, priceArs: 0),
    premium: const PlanPricing(priceUsd: 0, exchangeRate: 0, priceArs: 0),
    lastUpdated: DateTime.now(),
  );
}
