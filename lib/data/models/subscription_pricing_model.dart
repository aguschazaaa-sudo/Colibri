import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/subscription_pricing.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_pricing_model.freezed.dart';
part 'subscription_pricing_model.g.dart';

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

@freezed
class PlanPricingModel with _$PlanPricingModel {
  const factory PlanPricingModel({
    required double priceUsd,
    required double exchangeRate,
    required double priceArs,
  }) = _PlanPricingModel;

  const PlanPricingModel._();

  factory PlanPricingModel.fromJson(Map<String, dynamic> json) =>
      _$PlanPricingModelFromJson(json);

  PlanPricing toDomain() => PlanPricing(
    priceUsd: priceUsd,
    exchangeRate: exchangeRate,
    priceArs: priceArs,
  );
}

@freezed
class SubscriptionPricingModel with _$SubscriptionPricingModel {
  const factory SubscriptionPricingModel({
    required PlanPricingModel basic,
    required PlanPricingModel premium,
    @TimestampConverter() required DateTime lastUpdated,
  }) = _SubscriptionPricingModel;

  const SubscriptionPricingModel._();

  factory SubscriptionPricingModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPricingModelFromJson(json);

  factory SubscriptionPricingModel.fromFirestore(DocumentSnapshot doc) {
    return SubscriptionPricingModel.fromJson(
      doc.data() as Map<String, dynamic>,
    );
  }

  SubscriptionPricing toDomain() => SubscriptionPricing(
    basic: basic.toDomain(),
    premium: premium.toDomain(),
    lastUpdated: lastUpdated,
  );
}
