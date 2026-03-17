import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/domain/provider.dart' as domain;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cobrador/domain/subscription_pricing.dart';
import 'package:cobrador/presentation/providers/subscription_pricing_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

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

class _SubscriptionContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final daysLeft =
        provider?.subscriptionExpiresAt != null
            ? provider!.subscriptionExpiresAt!.difference(DateTime.now()).inDays
            : 0;

    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 0,
      locale: 'es_AR',
    );

    final basicPriceOriginal =
        pricing != null
            ? currencyFormat.format(pricing!.basic.priceArs)
            : r'$10.000'; // Fallback
    final premiumPriceOriginal =
        pricing != null
            ? currencyFormat.format(pricing!.premium.priceArs)
            : r'$20.000'; // Fallback

    final discountPercentage = provider?.discountPercentage ?? 0.0;

    final basicPriceFinal =
        pricing != null
            ? currencyFormat.format(
              pricing!.basic.priceArs * (1 - discountPercentage),
            )
            : currencyFormat.format(
              10000 * (1 - discountPercentage),
            ); // Fallback

    final premiumPriceFinal =
        pricing != null
            ? currencyFormat.format(
              pricing!.premium.priceArs * (1 - discountPercentage),
            )
            : currencyFormat.format(
              20000 * (1 - discountPercentage),
            ); // Fallback

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

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
                    _HeaderSection(daysLeft: daysLeft),
                    const SizedBox(height: 40),
                    if (isWide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _PlanCard(
                                    title: 'Plan Básico',
                                    price: '$basicPriceFinal/mes',
                                    originalPrice:
                                        discountPercentage > 0
                                            ? '$basicPriceOriginal/mes'
                                            : null,
                                    description:
                                        'Ideal para empezar a organizar tus cobros.',
                                    features: const [
                                      'Registro ilimitado de pacientes',
                                      'Carga de turnos y pagos',
                                      'Cálculo automático de deuda',
                                      'Soporte por email',
                                    ],
                                    isPremium: false,
                                    isStretch: true,
                                    onPressed:
                                        () =>
                                            _handleSubscription(context, false),
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
                                    originalPrice:
                                        discountPercentage > 0
                                            ? '$premiumPriceOriginal/mes'
                                            : null,
                                    description:
                                        'Potencia tu negocio con automatizaciones.',
                                    features: const [
                                      'Todo lo del Plan Básico',
                                      'Notificaciones WhatsApp automáticas',
                                      'Recordatorios de Turnos',
                                      'Estadísticas avanzadas',
                                      'Soporte prioritario',
                                    ],
                                    isPremium: true,
                                    isStretch: true,
                                    onPressed:
                                        () =>
                                            _handleSubscription(context, true),
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 200.ms)
                                  .slideY(begin: 0.2),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          _PlanCard(
                                title: 'Plan Básico',
                                price: '$basicPriceFinal/mes',
                                originalPrice:
                                    discountPercentage > 0
                                        ? '$basicPriceOriginal/mes'
                                        : null,
                                description:
                                    'Ideal para empezar a organizar tus cobros.',
                                features: const [
                                  'Registro ilimitado de pacientes',
                                  'Carga de turnos y pagos',
                                  'Cálculo automático de deuda',
                                  'Soporte por email',
                                ],
                                isPremium: false,
                                onPressed:
                                    () => _handleSubscription(context, false),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 24),
                          _PlanCard(
                                title: 'Plan Premium',
                                price: '$premiumPriceFinal/mes',
                                originalPrice:
                                    discountPercentage > 0
                                        ? '$premiumPriceOriginal/mes'
                                        : null,
                                description:
                                    'Potencia tu negocio con automatizaciones.',
                                features: const [
                                  'Todo lo del Plan Básico',
                                  'Notificaciones WhatsApp automáticas',
                                  'Recordatorios de Turnos',
                                  'Estadísticas avanzadas',
                                  'Soporte prioritario',
                                ],
                                isPremium: true,
                                onPressed:
                                    () => _handleSubscription(context, true),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: 0.2),
                        ],
                      ),
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Handled via ref in the parent usually, but here we can use a provider read if needed
                        },
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

class _HeaderSection extends StatelessWidget {
  final int daysLeft;

  const _HeaderSection({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elige tu plan',
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
