import 'package:flutter/material.dart';

import 'package:cobrador/domain/provider.dart' as domain;
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Atom: pill badge that reflects the provider's current plan or trial status.
///
/// When [isTrial] is `true` the badge always shows "Prueba gratuita",
/// regardless of [plan].  Otherwise the badge reflects [plan]:
/// - `premium` → tertiary tones + crown icon + "Premium ✦"
/// - `basic`   → secondary tones + "Básico"
/// - `none`    → surface tones + "Sin plan"
class PlanBadge extends StatelessWidget {
  const PlanBadge({
    super.key,
    required this.plan,
    required this.isTrial,
  });

  final domain.SubscriptionPlan plan;
  final bool isTrial;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (bgColor, fgColor, label, icon) = isTrial
        ? (
            colorScheme.secondaryContainer,
            colorScheme.onSecondaryContainer,
            'Prueba gratuita',
            Icons.hourglass_top,
          )
        : switch (plan) {
            domain.SubscriptionPlan.premium => (
                colorScheme.tertiaryContainer,
                colorScheme.onTertiaryContainer,
                'Premium ✦',
                Icons.workspace_premium,
              ),
            domain.SubscriptionPlan.basic => (
                colorScheme.secondaryContainer,
                colorScheme.onSecondaryContainer,
                'Básico',
                null,
              ),
            domain.SubscriptionPlan.none => (
                colorScheme.surfaceContainerHighest,
                colorScheme.onSurfaceVariant,
                'Sin plan',
                null,
              ),
          };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
