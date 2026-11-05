import 'package:cobrador/domain/dashboard_report.dart';
import 'package:cobrador/domain/monthly_snapshot.dart';
import 'package:cobrador/presentation/providers/dashboard_provider.dart';
import 'package:cobrador/presentation/providers/monthly_snapshots_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Bar chart showing the last 12 months of collected revenue and outstanding
/// debt side by side.
///
/// Past months come from [monthlySnapshotsProvider] (closed snapshots).
/// The current month comes from [dashboardReportProvider] and is displayed
/// as a "provisional" bar — visually distinct to indicate it's still in
/// progress.
class MonthlyRevenueChart extends ConsumerWidget {
  final String providerId;

  const MonthlyRevenueChart({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync =
        ref.watch(monthlySnapshotsProvider(providerId: providerId));
    final dashboardAsync = ref.watch(dashboardReportProvider(providerId));

    // Show skeleton while either source is loading.
    if (snapshotsAsync.isLoading || dashboardAsync.isLoading) {
      return Skeletonizer(
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (snapshotsAsync.hasError) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_outlined,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(
                  monthlySnapshotsProvider(providerId: providerId),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final snapshots = snapshotsAsync.value ?? [];
    final dashboard = dashboardAsync.value ?? DashboardReport.empty();

    // The query returns DESC; reverse for chronological display.
    final ordered = snapshots.reversed.toList();

    // Check if the current month already has a closed snapshot (edge case
    // where the cron ran today). If not, append a provisional bar.
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final alreadyClosed = ordered.any((s) => s.month == currentMonthKey);

    if (ordered.isEmpty && dashboard.monthlyRevenue == 0 && alreadyClosed) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 40),
              SizedBox(height: 8),
              Text(
                'Los datos de historial aparecerán a partir del próximo mes.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 216,
          child: _RevenueBarChart(
            snapshots: ordered,
            currentMonthRevenue: alreadyClosed ? null : dashboard.monthlyRevenue,
            currentMonthDebt:
                alreadyClosed ? null : dashboard.totalToCollect,
            currentMonthKey: alreadyClosed ? null : currentMonthKey,
            currentMonthIndex: now.month - 1,
            currentYear: now.year,
          ),
        ),
        const SizedBox(height: 8),
        _ChartLegend(),
      ],
    );
  }
}

/// Simple two-item legend row shown below the chart.
class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: colorScheme.primary),
        const SizedBox(width: 4),
        Text('Cobrado', style: labelStyle),
        const SizedBox(width: 16),
        _LegendDot(color: colorScheme.error.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text('Pendiente', style: labelStyle),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final List<MonthlySnapshot> snapshots;

  /// If non-null, a provisional bar for the current in-progress month is
  /// appended.
  final double? currentMonthRevenue;
  final double? currentMonthDebt;
  final String? currentMonthKey;
  final int currentMonthIndex;
  final int currentYear;

  const _RevenueBarChart({
    required this.snapshots,
    this.currentMonthRevenue,
    this.currentMonthDebt,
    this.currentMonthKey,
    this.currentMonthIndex = 0,
    this.currentYear = 0,
  });

  // Minimum pixel width allocated per bar group (two rods + spacing).
  // This prevents bars from stretching when there are only a few data points.
  static const double _minBarGroupWidth = 56.0;

  // Left-axis reserved size — kept consistent with the SideTitles config.
  static const double _yAxisReservedSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactFormat = NumberFormat.compactCurrency(
      locale: 'es_AR',
      symbol: r'$',
    );
    final fullFormat = NumberFormat.currency(locale: 'es_AR', symbol: r'$');
    final monthFormat = DateFormat('MMM', 'es');

    final hasProvisional = currentMonthRevenue != null;
    final totalBars = snapshots.length + (hasProvisional ? 1 : 0);

    final maxValue = [
      ...snapshots.map((s) => s.totalRevenue),
      ...snapshots.map((s) => s.totalDebt),
      if (hasProvisional) currentMonthRevenue!,
      if (hasProvisional) (currentMonthDebt ?? 0.0),
    ].fold(0.0, (a, b) => a > b ? a : b);

    final barGroups = _buildBarGroups(colorScheme, hasProvisional);
    final chartData = _buildChartData(
      context: context,
      colorScheme: colorScheme,
      compactFormat: compactFormat,
      fullFormat: fullFormat,
      monthFormat: monthFormat,
      barGroups: barGroups,
      maxValue: maxValue,
      hasProvisional: hasProvisional,
      totalBars: totalBars,
    );

    // LayoutBuilder to measure available width and decide whether to scroll.
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - _yAxisReservedSize - AppSpacing.xs;
        final requiredWidth =
            (totalBars * _minBarGroupWidth).clamp(availableWidth, double.infinity);
        final needsScroll = requiredWidth > availableWidth;

        final chart = SizedBox(
          width: needsScroll ? requiredWidth + _yAxisReservedSize : constraints.maxWidth,
          height: 216,
          child: BarChart(chartData),
        );

        if (!needsScroll) return chart;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: chart,
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    ColorScheme colorScheme,
    bool hasProvisional,
  ) {
    final groups = snapshots.asMap().entries.map((entry) {
      final s = entry.value;
      return BarChartGroupData(
        x: entry.key,
        groupVertically: false,
        barRods: [
          BarChartRodData(
            toY: s.totalRevenue,
            color: colorScheme.primary,
            width: 10,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: s.totalDebt,
            color: colorScheme.error.withValues(alpha: 0.6),
            width: 10,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    if (hasProvisional) {
      groups.add(
        BarChartGroupData(
          x: snapshots.length,
          groupVertically: false,
          barRods: [
            BarChartRodData(
              toY: currentMonthRevenue!,
              color: colorScheme.primary.withValues(alpha: 0.38),
              width: 10,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            BarChartRodData(
              toY: currentMonthDebt ?? 0.0,
              color: colorScheme.error.withValues(alpha: 0.3),
              width: 10,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              borderSide: BorderSide(
                color: colorScheme.error.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  BarChartData _buildChartData({
    required BuildContext context,
    required ColorScheme colorScheme,
    required NumberFormat compactFormat,
    required NumberFormat fullFormat,
    required DateFormat monthFormat,
    required List<BarChartGroupData> barGroups,
    required double maxValue,
    required bool hasProvisional,
    required int totalBars,
  }) {
    return BarChartData(
      maxY: maxValue > 0 ? maxValue * 1.2 : 100,
      barGroups: barGroups,
      groupsSpace: 6,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colorScheme.outlineVariant,
          strokeWidth: 0.8,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _yAxisReservedSize,
            getTitlesWidget: (value, meta) {
              if (value == meta.max) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Text(
                  compactFormat.format(value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= totalBars) {
                return const SizedBox.shrink();
              }
              final isProvisional =
                  hasProvisional && index == snapshots.length;
              final label = isProvisional
                  ? monthFormat
                      .format(DateTime(currentYear, currentMonthIndex + 1))
                  : monthFormat.format(DateTime(
                      snapshots[index].year,
                      snapshots[index].monthIndex + 1,
                    ));

              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isProvisional
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isProvisional
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                    if (isProvisional)
                      Text(
                        'en curso',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontSize: 8,
                                ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => colorScheme.inverseSurface,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final isProvisional =
                hasProvisional && group.x == snapshots.length;
            final double amount;
            final String label;
            if (rodIndex == 0) {
              amount = isProvisional
                  ? currentMonthRevenue!
                  : snapshots[group.x].totalRevenue;
              label = isProvisional
                  ? 'en curso\n${fullFormat.format(amount)}'
                  : fullFormat.format(amount);
            } else {
              amount = isProvisional
                  ? (currentMonthDebt ?? 0.0)
                  : snapshots[group.x].totalDebt;
              label = 'Pendiente\n${fullFormat.format(amount)}';
            }
            return BarTooltipItem(
              label,
              Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: colorScheme.onInverseSurface,
                  ),
            );
          },
        ),
      ),
    );
  }
}
