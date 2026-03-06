import 'package:cobrador/presentation/providers/dashboard_provider.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';

class DashboardMetrics extends ConsumerWidget {
  const DashboardMetrics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid ?? '';

    final metricsAsync = ref.watch(dashboardReportProvider(providerId));
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 0,
      locale: 'es_AR',
    );

    return metricsAsync.when(
      data: (metrics) => _buildContent(context, metrics, currencyFormat),
      loading:
          () =>
              Skeletonizer(child: _buildContent(context, null, currencyFormat)),
      error: (err, stack) => const SizedBox.shrink(), // Or an error widget
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic metrics,
    NumberFormat currencyFormat,
  ) {
    final toCollect =
        metrics?.totalToCollect ?? 45000.0; // Mock value for skeleton
    final revenue = metrics?.monthlyRevenue ?? 120000.0;

    return Padding(
      padding: AppSpacing.edgeInsetsH,
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
                  title: 'A Cobrar',
                  amount: currencyFormat.format(toCollect),
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.error,
                  isAlert: true,
                )
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _MetricCard(
                  title: 'Ingresado',
                  amount: currencyFormat.format(revenue),
                  icon: Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  isAlert: false,
                )
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
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
