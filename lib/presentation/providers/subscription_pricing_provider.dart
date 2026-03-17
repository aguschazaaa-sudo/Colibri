import 'package:cobrador/domain/subscription_pricing.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_pricing_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<SubscriptionPricing> subscriptionPricing(SubscriptionPricingRef ref) {
  return ref.watch(providerRepositoryProvider).watchSubscriptionPricing();
}
