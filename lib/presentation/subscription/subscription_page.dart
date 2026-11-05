import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/domain/provider.dart' as domain;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cobrador/domain/subscription_pricing.dart';
import 'package:cobrador/presentation/providers/subscription_pricing_provider.dart';
import 'package:cobrador/presentation/providers/provider_profile_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';
import 'package:cobrador/presentation/subscription/widgets/active_plan_hero_card.dart';
import 'package:cobrador/presentation/subscription/widgets/subscription_status_card.dart';
import 'package:cobrador/presentation/subscription/widgets/plan_features_card.dart';
import 'package:cobrador/presentation/subscription/widgets/subscription_actions.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: authState.when(
            data: (provider) => _SubscriptionPricingLayer(provider: provider),
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar tu perfil',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(authStateProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPricingLayer extends ConsumerWidget {
  final domain.Provider? provider;

  const _SubscriptionPricingLayer({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingAsync = ref.watch(subscriptionPricingProvider);

    return pricingAsync.when(
      data:
          (pricing) =>
              _SubscriptionContent(provider: provider, pricing: pricing),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (err, stack) => _SubscriptionContent(
            provider: provider,
            // Fallback pricing if DB document is missing but user provided values
            pricing: null,
          ),
    );
  }
}

class _SubscriptionContent extends ConsumerWidget {
  final domain.Provider? provider;
  final SubscriptionPricing? pricing;

  const _SubscriptionContent({required this.provider, this.pricing});

  Future<void> _handleSubscription(BuildContext context, bool isPremium) async {
    try {
      final functions = FirebaseFunctions.instance;
      // In the backend, the module is "subscriptions" and the function is "createSubscription"
      final callable = functions.httpsCallable(
        'subscriptions-createSubscription',
      );
      final response = await callable.call(<String, dynamic>{
        'planId': isPremium ? 'premium' : 'basic',
      });

      final String? url = response.data['init_point'];
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_self',
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudo abrir el navegador para procesar el pago.',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hubo un error al generar el pago: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveProvider = provider != null
        ? ref.watch(providerProfileProvider(provider!.id)).valueOrNull ?? provider
        : provider;
    final daysLeft =
        liveProvider?.subscriptionExpiresAt != null
            ? liveProvider!.subscriptionExpiresAt!.difference(DateTime.now()).inDays
            : 0;

    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 0,
      locale: 'es_AR',
    );

    final discountPercentage = provider?.discountPercentage ?? 0.0;

    final basicPriceOriginal =
        pricing != null
            ? currencyFormat.format(pricing!.basic.priceArs)
            : r'$10.000';
    final premiumPriceOriginal =
        pricing != null
            ? currencyFormat.format(pricing!.premium.priceArs)
            : r'$20.000';

    final basicPriceFinal =
        pricing != null
            ? currencyFormat.format(
              pricing!.basic.priceArs * (1 - discountPercentage),
            )
            : currencyFormat.format(10000 * (1 - discountPercentage));

    final premiumPriceFinal =
        pricing != null
            ? currencyFormat.format(
              pricing!.premium.priceArs * (1 - discountPercentage),
            )
            : currencyFormat.format(20000 * (1 - discountPercentage));

    final hasActivePlan = liveProvider?.hasActivePlan == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderSection(
                      daysLeft: daysLeft,
                      hasActivePlan: hasActivePlan,
                    ),
                    const SizedBox(height: 40),
                    if (hasActivePlan)
                      _ActivePlanView(
                        liveProvider: liveProvider!,
                        basicPriceFinal: basicPriceFinal,
                        premiumPriceFinal: premiumPriceFinal,
                        basicPriceOriginal:
                            discountPercentage > 0 ? basicPriceOriginal : null,
                        premiumPriceOriginal:
                            discountPercentage > 0 ? premiumPriceOriginal : null,
                        onSubscribe: _handleSubscription,
                      )
                    else
                      _PlanSelectionView(
                        isWide: constraints.maxWidth > 800,
                        basicPriceFinal: basicPriceFinal,
                        premiumPriceFinal: premiumPriceFinal,
                        basicPriceOriginal:
                            discountPercentage > 0
                                ? '$basicPriceOriginal/mes'
                                : null,
                        premiumPriceOriginal:
                            discountPercentage > 0
                                ? '$premiumPriceOriginal/mes'
                                : null,
                        onSubscribe: _handleSubscription,
                      ),
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const _LogoutButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivePlanView extends ConsumerWidget {
  final domain.Provider liveProvider;
  final String basicPriceFinal;
  final String premiumPriceFinal;
  final String? basicPriceOriginal;
  final String? premiumPriceOriginal;
  final Future<void> Function(BuildContext, bool) onSubscribe;

  const _ActivePlanView({
    required this.liveProvider,
    required this.basicPriceFinal,
    required this.premiumPriceFinal,
    this.basicPriceOriginal,
    this.premiumPriceOriginal,
    required this.onSubscribe,
  });

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cancelar suscripción?'),
        content: const Text(
          'Tu acceso continuará hasta el final del período actual. '
          'Después se desactivarán las funcionalidades del plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'subscriptions-cancelSubscription',
      );
      await callable.call();

      if (!context.mounted) return;

      ref.invalidate(providerProfileProvider(liveProvider.id));
      ref.invalidate(authStateProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu suscripción fue cancelada. El acceso continúa hasta el fin del período.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar la suscripción: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = liveProvider.plan == domain.SubscriptionPlan.premium;
    final planName = isPremium ? 'Premium' : 'Básico';
    final currentPrice = isPremium ? premiumPriceFinal : basicPriceFinal;
    final currentOriginalPrice =
        isPremium ? premiumPriceOriginal : basicPriceOriginal;
    final alternatePlanName = isPremium ? 'Básico' : 'Premium';
    final alternatePlanPrice = isPremium ? basicPriceFinal : premiumPriceFinal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivePlanHeroCard(
          planName: planName,
          isPremium: isPremium,
          currentPrice: currentPrice,
          originalPrice: currentOriginalPrice,
        ),
        const SizedBox(height: 16),
        SubscriptionStatusCard(
          status: liveProvider.subscriptionStatus,
          expiresAt: liveProvider.subscriptionExpiresAt,
          cancelPending: false,
        ),
        const SizedBox(height: 16),
        PlanFeaturesCard(isPremium: isPremium),
        const SizedBox(height: 16),
        SubscriptionActions(
          isPremium: isPremium,
          alternatePlanName: alternatePlanName,
          alternatePlanPrice: alternatePlanPrice,
          onChangePlan: () => onSubscribe(context, !isPremium),
          onCancel: () => _handleCancel(context, ref),
        ),
      ],
    );
  }
}

class _PlanSelectionView extends StatelessWidget {
  final bool isWide;
  final String basicPriceFinal;
  final String premiumPriceFinal;
  final String? basicPriceOriginal;
  final String? premiumPriceOriginal;
  final Future<void> Function(BuildContext, bool) onSubscribe;

  const _PlanSelectionView({
    required this.isWide,
    required this.basicPriceFinal,
    required this.premiumPriceFinal,
    this.basicPriceOriginal,
    this.premiumPriceOriginal,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PlanCard(
                    title: 'Plan Básico',
                    price: '$basicPriceFinal/mes',
                    originalPrice: basicPriceOriginal,
                    description: 'Ideal para empezar a organizar tus cobros.',
                    features: const [
                      'Registro ilimitado de pacientes',
                      'Seguimiento automático de deudas por WhatsApp',
                      'Hasta 150 recordatorios de WhatsApp al mes',
                      'Reportes financieros mensuales',
                      'Soporte por email',
                    ],
                    isPremium: false,
                    isStretch: true,
                    onPressed: () => onSubscribe(context, false),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _PlanCard(
                    title: 'Plan Premium',
                    price: '$premiumPriceFinal/mes',
                    originalPrice: premiumPriceOriginal,
                    description:
                        'Todo lo del plan Básico, más recordatorios de turnos sin límites.',
                    features: const [
                      'Todo lo incluido en el plan Básico',
                      'Recordatorios de turnos por WhatsApp ilimitados',
                      'Soporte prioritario por WhatsApp',
                      'Acceso a nuevas funcionalidades primero',
                    ],
                    isPremium: true,
                    isStretch: true,
                    onPressed: () => onSubscribe(context, true),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: 0.2),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _PlanCard(
              title: 'Plan Básico',
              price: '$basicPriceFinal/mes',
              originalPrice: basicPriceOriginal,
              description: 'Ideal para empezar a organizar tus cobros.',
              features: const [
                'Registro ilimitado de pacientes',
                'Seguimiento automático de deudas por WhatsApp',
                'Hasta 150 recordatorios de WhatsApp al mes',
                'Reportes financieros mensuales',
                'Soporte por email',
              ],
              isPremium: false,
              onPressed: () => onSubscribe(context, false),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.2),
        const SizedBox(height: 24),
        _PlanCard(
              title: 'Plan Premium',
              price: '$premiumPriceFinal/mes',
              originalPrice: premiumPriceOriginal,
              description:
                  'Todo lo del plan Básico, más recordatorios de turnos sin límites.',
              features: const [
                'Todo lo incluido en el plan Básico',
                'Recordatorios de turnos por WhatsApp ilimitados',
                'Soporte prioritario por WhatsApp',
                'Acceso a nuevas funcionalidades primero',
              ],
              isPremium: true,
              onPressed: () => onSubscribe(context, true),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.2),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int daysLeft;
  final bool hasActivePlan;

  const _HeaderSection({required this.daysLeft, required this.hasActivePlan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasActivePlan ? 'Tu suscripción' : 'Elige tu plan',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ).animate().fadeIn().slideX(),
        const SizedBox(height: 8),
        if (daysLeft > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Te quedan $daysLeft días de prueba gratuita',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().shake(delay: 500.ms)
        else
          Text(
            'Tu periodo de prueba ha finalizado o no tienes un plan activo.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? originalPrice;
  final String description;
  final List<String> features;
  final bool isPremium;
  final Future<void> Function()? onPressed;
  final bool isStretch;

  const _PlanCard({
    required this.title,
    required this.price,
    this.originalPrice,
    required this.description,
    required this.features,
    required this.isPremium,
    required this.onPressed,
    this.isStretch = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPremium ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border:
            isPremium ? null : Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        isPremium
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                  ),
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'RECOMENDADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (originalPrice != null)
            Text(
              originalPrice!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
                color:
                    isPremium
                        ? colorScheme.onPrimary.withOpacity(0.5)
                        : colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          Text(
            price,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color:
                  isPremium
                      ? colorScheme.onPrimary.withOpacity(0.9)
                      : colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color:
                  isPremium
                      ? colorScheme.onPrimary.withOpacity(0.7)
                      : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...features.map(
            (feature) => _FeatureRow(feature: feature, isPremium: isPremium),
          ),
          if (isStretch) const Spacer() else const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isPremium ? colorScheme.onPrimary : colorScheme.primary,
                foregroundColor:
                    isPremium ? colorScheme.primary : colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Seleccionar Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  final bool isPremium;

  const _FeatureRow({required this.feature, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color:
                isPremium
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color:
                    isPremium
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
      icon: const Icon(Icons.logout),
      label: const Text('Cerrar sesión'),
    );
  }
}
