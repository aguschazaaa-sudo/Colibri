// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_pricing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlanPricingModelImpl _$$PlanPricingModelImplFromJson(
  Map<String, dynamic> json,
) => _$PlanPricingModelImpl(
  priceUsd: (json['priceUsd'] as num).toDouble(),
  exchangeRate: (json['exchangeRate'] as num).toDouble(),
  priceArs: (json['priceArs'] as num).toDouble(),
);

Map<String, dynamic> _$$PlanPricingModelImplToJson(
  _$PlanPricingModelImpl instance,
) => <String, dynamic>{
  'priceUsd': instance.priceUsd,
  'exchangeRate': instance.exchangeRate,
  'priceArs': instance.priceArs,
};

_$SubscriptionPricingModelImpl _$$SubscriptionPricingModelImplFromJson(
  Map<String, dynamic> json,
) => _$SubscriptionPricingModelImpl(
  basic: PlanPricingModel.fromJson(json['basic'] as Map<String, dynamic>),
  premium: PlanPricingModel.fromJson(json['premium'] as Map<String, dynamic>),
  lastUpdated: const TimestampConverter().fromJson(
    json['lastUpdated'] as Timestamp,
  ),
);

Map<String, dynamic> _$$SubscriptionPricingModelImplToJson(
  _$SubscriptionPricingModelImpl instance,
) => <String, dynamic>{
  'basic': instance.basic,
  'premium': instance.premium,
  'lastUpdated': const TimestampConverter().toJson(instance.lastUpdated),
};
