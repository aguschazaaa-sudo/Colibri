import 'package:cobrador/domain/dashboard_report.dart';
import 'package:cobrador/domain/monthly_snapshot.dart';
import 'package:cobrador/presentation/finances/widgets/monthly_revenue_chart.dart';
import 'package:cobrador/presentation/home/widgets/dashboard_metrics.dart';
import 'package:cobrador/presentation/providers/dashboard_provider.dart';
import 'package:cobrador/presentation/providers/monthly_snapshots_provider.dart';
import 'package:cobrador/presentation/providers/payments_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'payment_history_item.dart';

class PaymentScrollView extends ConsumerWidget {
  final String providerId;
  final PaymentsState paymentsState;

  const PaymentScrollView({
    super.key,
    required this.providerId,
    required this.paymentsState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          sliver: SliverToBoxAdapter(child: DashboardMetrics()),
        ),
        SliverPadding(
          padding: AppSpacing.edgeInsetsH,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Historial de Ingresos',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                MonthlyRevenueChart(providerId: providerId),
                const SizedBox(height: AppSpacing.md),
                _AnnualMetrics(providerId: providerId),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: AppSpacing.edgeInsetsH,
          sliver: SliverToBoxAdapter(
            child: Text(
              'Últimos Movimientos',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        paymentsState.status.when(
          data: (_) => _buildPaymentsList(context, ref, paymentsState),
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => SliverToBoxAdapter(
            child: Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsList(
    BuildContext context,
    WidgetRef ref,
    PaymentsState state,
  ) {
    if (state.payments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text('No hay movimientos registrados')),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= state.payments.length) {
            if (state.hasMore) {
              Future.microtask(
                () => ref
                    .read(paymentsProvider(providerId).notifier)
                    .fetchNextPage(),
              );
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return null;
          }

          final payment = state.payments[index];
          return Column(
            children: [
              PaymentHistoryItem(payment: payment)
                  .animate(delay: (20 * (index % 8)).ms)
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideX(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
              if (index < state.payments.length - 1 || state.hasMore)
                const Divider(height: 1, indent: 72),
            ],
          );
        },
        childCount: state.payments.length + (state.hasMore ? 1 : 0),
      ),
    );
  }
}

/// Metrics summary card for the current calendar year.
///
/// Shows: yearly total, monthly average, best month, current total debt,
/// and a simple trend indicator comparing the last two closed months.
class _AnnualMetrics extends ConsumerWidget {
  final String providerId;

  const _AnnualMetrics({required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync =
        ref.watch(monthlySnapshotsProvider(providerId: providerId));
    final dashboardAsync = ref.watch(dashboardReportProvider(providerId));

    return snapshotsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshots) {
        if (snapshots.isEmpty &&
            !(dashboardAsync.valueOrNull?.monthlyRevenue != null &&
                dashboardAsync.valueOrNull!.monthlyRevenue > 0)) {
          return const SizedBox.shrink();
        }
        return _AnnualMetricsContent(
          snapshots: snapshots,
          dashboard: dashboardAsync.valueOrNull ?? DashboardReport.empty(),
        );
      },
    );
  }
}

class _AnnualMetricsContent extends StatelessWidget {
  final List<MonthlySnapshot> snapshots;
  final DashboardReport dashboard;

  const _AnnualMetricsContent({
    required this.snapshots,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final metrics = _computeMetrics(
      currentYear: currentYear,
      currentMonthKey: currentMonthKey,
      now: now,
      colorScheme: colorScheme,
    );

    final currency = NumberFormat.currency(locale: 'es_AR', symbol: r'$');
    final compact = NumberFormat.compactCurrency(
      locale: 'es_AR',
      symbol: r'$',
    );

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Resumen $currentYear',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (metrics.trendLabel != null) ...[
                  const Spacer(),
                  Icon(metrics.trendIcon, size: 16, color: metrics.trendColor),
                  const SizedBox(width: 2),
                  Text(
                    metrics.trendLabel!,
                    style: textTheme.labelSmall?.copyWith(
                      color: metrics.trendColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                _MetricChip(
                  label: 'Total año',
                  value: compact.format(metrics.totalYear),
                  icon: Icons.attach_money,
                  color: colorScheme.primary,
                ),
                _MetricChip(
                  label: 'Promedio mensual',
                  value: compact.format(metrics.avgMonthly),
                  icon: Icons.bar_chart,
                  color: colorScheme.secondary,
                ),
                if (metrics.bestMonthLabel != null)
                  _MetricChip(
                    label: 'Mejor mes',
                    value: metrics.bestMonthLabel!,
                    icon: Icons.emoji_events_outlined,
                    color: colorScheme.tertiary,
                  ),
                _MetricChip(
                  label: 'Saldo pendiente',
                  value: currency.format(metrics.latestDebt),
                  icon: Icons.account_balance_wallet_outlined,
                  color: colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _AnnualData _computeMetrics({
    required int currentYear,
    required String currentMonthKey,
    required DateTime now,
    required ColorScheme colorScheme,
  }) {
    final monthFormat = DateFormat('MMM', 'es');
    final compact = NumberFormat.compactCurrency(
      locale: 'es_AR',
      symbol: r'$',
    );

    // Filter to snapshots from the current calendar year.
    final yearSnapshots = snapshots
        .where((s) => s.year == currentYear)
        .toList()
      ..sort((a, b) => a.monthIndex.compareTo(b.monthIndex));

    // Check if the current month already has a closed snapshot.
    final alreadyClosed = yearSnapshots.any((s) => s.month == currentMonthKey);
    final includeProvisional =
        !alreadyClosed && dashboard.monthlyRevenue > 0;

    // Yearly total: closed snapshots + provisional current month.
    var totalYear = yearSnapshots.fold(0.0, (sum, s) => sum + s.totalRevenue);
    final monthCount = yearSnapshots.length + (includeProvisional ? 1 : 0);
    if (includeProvisional) totalYear += dashboard.monthlyRevenue;

    final avgMonthly = monthCount == 0 ? 0.0 : totalYear / monthCount;

    // Best month: compare closed snapshots and provisional current month.
    MonthlySnapshot? bestSnapshot;
    for (final s in yearSnapshots) {
      if (bestSnapshot == null || s.totalRevenue > bestSnapshot.totalRevenue) {
        bestSnapshot = s;
      }
    }
    final provisionalIsBest = includeProvisional &&
        (bestSnapshot == null ||
            dashboard.monthlyRevenue > bestSnapshot.totalRevenue);

    String? bestMonthLabel;
    if (provisionalIsBest) {
      final label = monthFormat.format(DateTime(now.year, now.month));
      bestMonthLabel = '$label \u2022 ${compact.format(dashboard.monthlyRevenue)}';
    } else if (bestSnapshot != null) {
      final label = monthFormat.format(
        DateTime(bestSnapshot.year, bestSnapshot.monthIndex + 1),
      );
      bestMonthLabel = '$label \u2022 ${compact.format(bestSnapshot.totalRevenue)}';
    }

    // Latest debt: prefer live dashboard over last closed snapshot.
    final latestDebt = !alreadyClosed
        ? dashboard.totalToCollect
        : (snapshots.isNotEmpty ? snapshots.first.totalDebt : 0.0);

    // Trend: compare the most recent revenue against the previous month.
    final ordered = [...snapshots.reversed];
    String? trendLabel;
    IconData? trendIcon;
    Color? trendColor;

    if (includeProvisional && ordered.isNotEmpty) {
      final prev = ordered.last.totalRevenue;
      if (prev > 0) {
        final delta =
            ((dashboard.monthlyRevenue - prev) / prev * 100).roundToDouble();
        (trendLabel, trendIcon, trendColor) =
            _trendValues(delta, colorScheme);
      }
    } else if (ordered.length >= 2) {
      final prev = ordered[ordered.length - 2].totalRevenue;
      final last = ordered[ordered.length - 1].totalRevenue;
      if (prev > 0) {
        final delta = ((last - prev) / prev * 100).roundToDouble();
        (trendLabel, trendIcon, trendColor) =
            _trendValues(delta, colorScheme);
      }
    }

    return _AnnualData(
      totalYear: totalYear,
      avgMonthly: avgMonthly,
      bestMonthLabel: bestMonthLabel,
      latestDebt: latestDebt,
      trendLabel: trendLabel,
      trendIcon: trendIcon,
      trendColor: trendColor,
    );
  }

  static (String, IconData, Color) _trendValues(
    double delta,
    ColorScheme colorScheme,
  ) {
    if (delta > 0) {
      return (
        '+${delta.toStringAsFixed(0)}%',
        Icons.trending_up,
        colorScheme.primary,
      );
    } else if (delta < 0) {
      return (
        '${delta.toStringAsFixed(0)}%',
        Icons.trending_down,
        colorScheme.error,
      );
    }
    return ('0%', Icons.trending_flat, colorScheme.onSurfaceVariant);
  }
}

/// Intermediate data holder for annual metrics calculations.
class _AnnualData {
  final double totalYear;
  final double avgMonthly;
  final String? bestMonthLabel;
  final double latestDebt;
  final String? trendLabel;
  final IconData? trendIcon;
  final Color? trendColor;

  const _AnnualData({
    required this.totalYear,
    required this.avgMonthly,
    required this.bestMonthLabel,
    required this.latestDebt,
    this.trendLabel,
    this.trendIcon,
    this.trendColor,
  });
}

/// A small labeled metric chip used inside [_AnnualMetricsContent].
class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
