import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// A visually rich hero card displaying the user's current subscription plan.
///
/// This is intended to be the most prominent element on the subscription
/// management page. It adapts its color scheme based on whether the active
/// plan is Premium or Básico.
class ActivePlanHeroCard extends StatelessWidget {
  const ActivePlanHeroCard({
    super.key,
    required this.planName,
    required this.isPremium,
    required this.currentPrice,
    this.originalPrice,
  });

  /// Display name of the plan, e.g. 'Básico' or 'Premium'.
  final String planName;

  /// Whether the plan is the premium tier (changes card styling).
  final bool isPremium;

  /// Formatted price string, e.g. "\$10.000".
  final String currentPrice;

  /// If a discount is active, the original price shown with strikethrough.
  final String? originalPrice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      color: isPremium
          ? colorScheme.primary
          : colorScheme.surfaceContainerHigh,
      child: Container(
        decoration: isPremium
            ? null
            : BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: colorScheme.primary,
                    width: 4,
                  ),
                ),
              ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BadgeRow(isPremium: isPremium),
            const SizedBox(height: AppSpacing.md),
            _PlanIdentity(
              planName: planName,
              isPremium: isPremium,
            ),
            const SizedBox(height: AppSpacing.md),
            _PriceRow(
              currentPrice: currentPrice,
              originalPrice: originalPrice,
              isPremium: isPremium,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15);
  }
}

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

/// "PLAN ACTUAL" badge aligned to the top-right of the card.
class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final badgeBackground = isPremium
        ? colorScheme.onPrimary.withValues(alpha: 0.15)
        : colorScheme.primary.withValues(alpha: 0.1);

    final badgeForeground = isPremium
        ? colorScheme.onPrimary
        : colorScheme.primary;

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: badgeBackground,
          borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
        ),
        child: Text(
          'PLAN ACTUAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: badgeForeground,
          ),
        ),
      ),
    );
  }
}

/// Plan icon + plan name row.
class _PlanIdentity extends StatelessWidget {
  const _PlanIdentity({
    required this.planName,
    required this.isPremium,
  });

  final String planName;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final avatarBackground = isPremium
        ? colorScheme.onPrimary.withValues(alpha: 0.2)
        : colorScheme.primaryContainer;

    final iconColor = isPremium
        ? colorScheme.onPrimary
        : colorScheme.primary;

    final textColor = isPremium
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Row(
      children: [
        CircleAvatar(
          radius: AppSpacing.lg,
          backgroundColor: avatarBackground,
          child: Icon(
            isPremium ? Icons.workspace_premium : Icons.verified_outlined,
            size: AppSpacing.lg,
            color: iconColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            planName,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Price display with optional original-price strikethrough.
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.currentPrice,
    this.originalPrice,
    required this.isPremium,
  });

  final String currentPrice;
  final String? originalPrice;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final priceColor = isPremium
        ? colorScheme.onPrimary
        : colorScheme.primary;

    final strikethroughColor = isPremium
        ? colorScheme.onPrimary.withValues(alpha: 0.45)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55);

    final suffixColor = isPremium
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (originalPrice != null) ...[
          Text(
            originalPrice!,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
              decorationColor: strikethroughColor,
              color: strikethroughColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          currentPrice,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: priceColor,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Text(
            '/mes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: suffixColor,
            ),
          ),
        ),
      ],
    );
  }
}
