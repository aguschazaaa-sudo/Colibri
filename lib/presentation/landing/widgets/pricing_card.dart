import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:intl/intl.dart';

class PricingCard extends StatelessWidget {
  const PricingCard({
    super.key,
    required this.title,
    required this.priceArs,
    required this.features,
    this.highlighted = false,
  });

  final String title;
  final int priceArs;
  final List<String> features;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: highlighted ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? colorScheme.primary : colorScheme.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
        boxShadow:
            highlighted
                ? [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(40),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: highlighted,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MÁS ELEGIDO',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  highlighted
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currencyFormat.format(priceArs),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color:
                        highlighted
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' / mes',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        highlighted
                            ? colorScheme.onPrimaryContainer.withAlpha(180)
                            : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.xl),
          ...features.map(
            (feature) => _FeatureItem(text: feature, highlighted: highlighted),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: highlighted ? colorScheme.primary : colorScheme.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color:
                    highlighted
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
