import 'package:flutter/material.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';

class DashboardMetrics extends StatelessWidget {
  const DashboardMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.edgeInsetsH,
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: 'A Cobrar',
              amount: '\$45.000',
              icon: Icons.trending_up,
              color: Theme.of(context).colorScheme.error,
              isAlert: true,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _MetricCard(
              title: 'Ingresado',
              amount: '\$120.000',
              icon: Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              isAlert: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _MetricCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isAlert,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // For positive metric use a custom success color scheme
    final cardColor =
        isAlert
            ? colorScheme.errorContainer
            : colorScheme
                .tertiaryContainer; // Tertiary could map to green in our theme
    final onCardColor =
        isAlert
            ? colorScheme.onErrorContainer
            : colorScheme.onTertiaryContainer;

    return Card(
      elevation: 0,
      color: cardColor.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: BorderSide(color: cardColor.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: onCardColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: textTheme.labelMedium?.copyWith(
                    color: onCardColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              amount,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: onCardColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
