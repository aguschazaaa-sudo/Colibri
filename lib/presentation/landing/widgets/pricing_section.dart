import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/landing/widgets/pricing_card.dart';
import 'package:cobrador/presentation/landing/widgets/scroll_reveal_wrapper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cobrador/presentation/providers/subscription_pricing_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PricingSection extends ConsumerWidget {
  const PricingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pricingAsync = ref.watch(subscriptionPricingProvider);

    return Padding(
      padding: AppSpacing.sectionPadding(context),
      child: AppSpacing.constrained(
        child: Column(
          children: [
            Text(
              'Planes simples y transparentes',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Elegí el plan que mejor se adapte a tus necesidades. Prueba gratuita de 5 días en cualquiera de ellos.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            ScrollRevealWrapper(
              childBuilder: (context, isVisible) {
                return pricingAsync.when(
                  data: (pricing) {
                    return _PricingGrid(
                      basicPriceArs: pricing.basic.priceArs.toInt(),
                      premiumPriceArs: pricing.premium.priceArs.toInt(),
                      isVisible: isVisible,
                    );
                  },
                  loading:
                      () => const Skeletonizer(
                        child: _PricingGrid(
                          basicPriceArs: 10000,
                          premiumPriceArs: 20000,
                          isVisible: true,
                        ),
                      ),
                  error:
                      (err, stack) => const _PricingGrid(
                        basicPriceArs: 10000,
                        premiumPriceArs: 20000,
                        isVisible: true,
                      ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // CTA Button for auth/register
            ScrollRevealWrapper(
              childBuilder: (context, isVisible) {
                return FilledButton.icon(
                      onPressed: () => context.go('/auth/register'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                      ),
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text(
                        'Comenzar prueba gratis de 5 días',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    .animate(target: isVisible ? 1 : 0)
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOut,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingGrid extends StatelessWidget {
  const _PricingGrid({
    required this.basicPriceArs,
    required this.premiumPriceArs,
    this.isVisible = false,
  });

  final int basicPriceArs;
  final int premiumPriceArs;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > AppSpacing.breakpointMd;

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PricingCard(
                    title: 'Básico',
                    priceArs: basicPriceArs,
                    features: const [
                      'Registro ilimitado de pacientes',
                      'Seguimiento automático de deudas',
                      'Hasta 150 recordatorios de WhatsApp al mes',
                      'Soporte por email',
                    ],
                  )
                  .animate(target: isVisible ? 1 : 0)
                  .fadeIn(duration: 400.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: PricingCard(
                    title: 'Premium',
                    priceArs: premiumPriceArs,
                    highlighted: true,
                    features: const [
                      'Todo lo incluido en el plan Básico',
                      'Recordatorios de WhatsApp ilimitados',
                      'Soporte prioritario por WhatsApp',
                      'Acceso a nuevas funcionalidades primero',
                    ],
                  )
                  .animate(target: isVisible ? 1 : 0)
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        PricingCard(
              title: 'Básico',
              priceArs: basicPriceArs,
              features: const [
                'Registro ilimitado de pacientes',
                'Seguimiento automático de deudas',
                'Hasta 150 recordatorios de WhatsApp al mes',
                'Soporte por email',
              ],
            )
            .animate(target: isVisible ? 1 : 0)
            .fadeIn(duration: 400.ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOut,
            ),
        const SizedBox(height: AppSpacing.xl),
        PricingCard(
              title: 'Premium',
              priceArs: premiumPriceArs,
              highlighted: true,
              features: const [
                'Todo lo incluido en el plan Básico',
                'Recordatorios de WhatsApp ilimitados',
                'Soporte prioritario por WhatsApp',
                'Acceso a nuevas funcionalidades primero',
              ],
            )
            .animate(target: isVisible ? 1 : 0)
            .fadeIn(delay: 150.ms, duration: 400.ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOut,
            ),
      ],
    );
  }
}
