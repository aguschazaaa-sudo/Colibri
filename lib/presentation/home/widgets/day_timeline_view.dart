import 'dart:ui';

import 'package:cobrador/presentation/home/widgets/atoms/current_time_indicator.dart';
import 'package:cobrador/presentation/home/widgets/atoms/projected_appointment_card.dart';
import 'package:cobrador/presentation/home/widgets/atoms/time_axis_column.dart';
import 'package:cobrador/presentation/home/widgets/today_appointment_card.dart';
import 'package:cobrador/presentation/providers/day_schedule_provider.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Pixels per minute on the vertical timeline axis.
const double _kPixelsPerMinute = 2.0;

/// Minimum card height in logical pixels regardless of duration.
const double _kMinCardHeight = 56.0;

/// Maximum visible cards per overlap slot before showing overflow badge.
const int _kMaxVisiblePerSlot = 2;

// ── Overlap grouping helper ─────────────────────────────────────────────────

/// Groups [DayScheduleItemWithLayout] entries that overlap each other and
/// have more than [_kMaxVisiblePerSlot] columns into overflow groups.
///
/// Items that don't belong to a crowded slot are returned as single-item
/// groups (rendered normally).
List<List<DayScheduleItemWithLayout>> _groupOverlappingItems(
  List<DayScheduleItemWithLayout> items,
) {
  if (items.isEmpty) return [];

  final used = <int>{};
  final groups = <List<DayScheduleItemWithLayout>>[];

  for (int i = 0; i < items.length; i++) {
    if (used.contains(i)) continue;

    final a = items[i];
    // Only create overflow groups for crowded slots (cols > _kMaxVisiblePerSlot)
    if (a.cols <= _kMaxVisiblePerSlot) {
      groups.add([a]);
      used.add(i);
      continue;
    }

    // Collect all items overlapping with `a`
    final group = <DayScheduleItemWithLayout>[a];
    used.add(i);

    for (int j = i + 1; j < items.length; j++) {
      if (used.contains(j)) continue;
      final b = items[j];
      // Check overlap with any item already in the group
      final overlaps = group.any(
        (g) =>
            g.item.startTime.isBefore(b.item.endTime) &&
            b.item.startTime.isBefore(g.item.endTime),
      );
      if (overlaps && b.cols > _kMaxVisiblePerSlot) {
        group.add(b);
        used.add(j);
      }
    }

    groups.add(group);
  }

  return groups;
}

// ── Organism: DayTimelineView ─────────────────────────────────────────────────

/// Organism: scrollable vertical timeline for a single [selectedDate].
///
/// Positions appointment cards absolutely using a [Stack]. Overlapping
/// appointments are rendered side-by-side using [assignColumns].
///
/// Auto-scrolls to current time when [isToday] is true and [selectedDate]
/// changes (or on first build).
class DayTimelineView extends ConsumerStatefulWidget {
  const DayTimelineView({
    super.key,
    required this.items,
    required this.selectedDate,
    required this.isToday,
    required this.providerId,
    this.scrollController,
  });

  final List<DayScheduleItem> items;
  final DateTime selectedDate;
  final bool isToday;
  final String providerId;
  final ScrollController? scrollController;

  @override
  ConsumerState<DayTimelineView> createState() => _DayTimelineViewState();
}

class _DayTimelineViewState extends ConsumerState<DayTimelineView> {
  late ScrollController _scrollController;
  bool _ownsScrollController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
    if (widget.isToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    } else if (widget.items.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToFirstItem());
    }
  }

  @override
  void didUpdateWidget(DayTimelineView old) {
    super.didUpdateWidget(old);
    final dateChanged =
        old.selectedDate.year != widget.selectedDate.year ||
        old.selectedDate.month != widget.selectedDate.month ||
        old.selectedDate.day != widget.selectedDate.day;
    if (dateChanged && widget.isToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    } else if (dateChanged && !widget.isToday && widget.items.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToFirstItem());
    }
  }

  @override
  void dispose() {
    if (_ownsScrollController) _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFirstItem() {
    if (!_scrollController.hasClients) return;
    if (widget.items.isEmpty) return;
    final firstStart = widget.items
        .map((i) => i.startTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final firstStartMinutes = firstStart.hour * 60 + firstStart.minute;
    final rangeStart = _computeRangeStart(widget.items);
    final offset = (firstStartMinutes - 30 - rangeStart) * _kPixelsPerMinute;
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final rangeStart = _computeRangeStart(widget.items);
    final offset =
        (nowMinutes - rangeStart) * _kPixelsPerMinute -
        _scrollController.position.viewportDimension / 3;
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final rangeStartHour = _computeRangeStartHour(items);
    final rangeEndHour = _computeRangeEndHour(items);
    final rangeStartMinutes = rangeStartHour * 60;
    final totalMinutes = (rangeEndHour - rangeStartHour) * 60;
    final stackHeight = totalMinutes * _kPixelsPerMinute;
    final withLayout = assignColumns(items);
    final overflowGroups = _groupOverlappingItems(withLayout);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(
          bottom:
              kFloatingActionButtonMargin +
              56 +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed time axis on the left
            SizedBox(
              height: stackHeight,
              child: TimeAxisColumn(
                rangeStartHour: rangeStartHour,
                rangeEndHour: rangeEndHour,
                pixelsPerMinute: _kPixelsPerMinute,
              ),
            ),
            // Appointments area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  return SizedBox(
                    height: stackHeight,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        _buildHourDividers(context, rangeStartHour, rangeEndHour),
                        ..._buildGroupedCards(
                          context,
                          overflowGroups,
                          rangeStartMinutes,
                          availableWidth,
                        ),
                        // Current time indicator (today only)
                        if (widget.isToday)
                          CurrentTimeIndicator(
                            rangeStartMinutes: rangeStartMinutes,
                            pixelsPerMinute: _kPixelsPerMinute,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourDividers(
    BuildContext context,
    int rangeStartHour,
    int rangeEndHour,
  ) {
    return Positioned.fill(
      child: CustomPaint(
        painter: TimeAxisLines(
          rangeStartHour: rangeStartHour,
          rangeEndHour: rangeEndHour,
          pixelsPerMinute: _kPixelsPerMinute,
          lineColor: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  /// Builds positioned cards for all overflow groups.
  ///
  /// Groups with <= [_kMaxVisiblePerSlot] items render normally.
  /// Larger groups render only the first 2 items, with a [_SlotOverflowBadge]
  /// overlaid on the second card.
  List<Widget> _buildGroupedCards(
    BuildContext context,
    List<List<DayScheduleItemWithLayout>> groups,
    int rangeStartMinutes,
    double availableWidth,
  ) {
    final widgets = <Widget>[];

    for (final group in groups) {
      if (group.length <= _kMaxVisiblePerSlot) {
        // Render all items normally
        for (final entry in group) {
          widgets.add(
            _buildPositionedItem(context, entry, rangeStartMinutes, availableWidth),
          );
        }
      } else {
        // Render first 2 items; overlay badge on the second
        final visibleItems = group.take(_kMaxVisiblePerSlot).toList();
        final overflowCount = group.length - _kMaxVisiblePerSlot;
        final allGroupItems = group.map((e) => e.item).toList();

        for (int i = 0; i < visibleItems.length; i++) {
          widgets.add(
            _buildPositionedItem(
              context,
              visibleItems[i],
              rangeStartMinutes,
              availableWidth,
            ),
          );
        }

        // Add the overflow badge on top of the second card (z-order: after)
        final secondEntry = visibleItems.last;
        widgets.add(
          _buildOverflowBadgePositioned(
            context,
            secondEntry,
            rangeStartMinutes,
            availableWidth,
            overflowCount,
            allGroupItems,
          ),
        );
      }
    }

    return widgets;
  }

  /// Positions the [_SlotOverflowBadge] at the top-right corner of [entry].
  Widget _buildOverflowBadgePositioned(
    BuildContext context,
    DayScheduleItemWithLayout entry,
    int rangeStartMinutes,
    double availableWidth,
    int overflowCount,
    List<DayScheduleItem> allGroupItems,
  ) {
    final startMinutes =
        entry.item.startTime.hour * 60 + entry.item.startTime.minute;
    final top = (startMinutes - rangeStartMinutes) * _kPixelsPerMinute;
    final colWidth = availableWidth / entry.cols;
    final left = entry.col * colWidth;

    return Positioned(
      top: top,
      left: left + colWidth - AppSpacing.xs - 32,
      child: _SlotOverflowBadge(
        count: overflowCount,
        groupItems: allGroupItems,
        providerId: widget.providerId,
      ),
    );
  }

  Widget _buildPositionedItem(
    BuildContext context,
    DayScheduleItemWithLayout entry,
    int rangeStartMinutes,
    double availableWidth,
  ) {
    final item = entry.item;
    final startMinutes =
        item.startTime.hour * 60 + item.startTime.minute;
    final endMinutes = item.endTime.hour * 60 + item.endTime.minute;
    final durationMinutes = (endMinutes - startMinutes).clamp(1, 1440);

    final top = (startMinutes - rangeStartMinutes) * _kPixelsPerMinute;
    final height = (durationMinutes * _kPixelsPerMinute).clamp(
      _kMinCardHeight,
      double.infinity,
    );

    final colWidth = availableWidth / entry.cols;
    final left = entry.col * colWidth;

    return Positioned(
      top: top,
      left: left,
      width: colWidth - AppSpacing.xs,
      height: height,
      child: _buildCard(context, item),
    );
  }

  Widget _buildCard(BuildContext context, DayScheduleItem item) {
    return switch (item) {
      RealDayItem() => _RealItemCard(item: item, providerId: widget.providerId),
      ProjectedDayItem() => _ProjectedItemCard(item: item, providerId: widget.providerId),
    };
  }
}

// ── Atom: +N overflow badge ─────────────────────────────────────────────────

/// Small circular badge showing "+N" to indicate additional overlapping
/// appointments that are hidden for visual clarity.
///
/// Tapping opens a [_SlotOverflowSheet] with the full list of items in the
/// overlap group.
class _SlotOverflowBadge extends StatelessWidget {
  const _SlotOverflowBadge({
    required this.count,
    required this.groupItems,
    required this.providerId,
  });

  final int count;
  final List<DayScheduleItem> groupItems;
  final String providerId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget badge = GestureDetector(
      onTap: () => _showOverflowSheet(context),
      child: Material(
        color: colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 2,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Text(
              '+$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    // Entry animation
    badge = badge
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 400.ms,
        );

    // Idle pulse — only if animations are enabled
    if (!reduceMotion) {
      badge = badge
          .animate(
            delay: 1400.ms,
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.14, 1.14),
            duration: 550.ms,
            curve: Curves.easeInOut,
          );
    }

    return RepaintBoundary(child: badge);
  }

  void _showOverflowSheet(BuildContext context) {
    // Compute time range label from the group
    final earliest = groupItems
        .map((i) => i.startTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = groupItems
        .map((i) => i.endTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SlotOverflowSheet(
        groupItems: groupItems,
        providerId: providerId,
        rangeStart: earliest,
        rangeEnd: latest,
      ),
    );
  }
}

// ── Organism: overflow bottom sheet ─────────────────────────────────────────

/// Bottom sheet listing all items in an overflow group at full width.
///
/// Opened by [_SlotOverflowBadge] when the user taps "+N".
class _SlotOverflowSheet extends ConsumerWidget {
  const _SlotOverflowSheet({
    required this.groupItems,
    required this.providerId,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final List<DayScheduleItem> groupItems;
  final String providerId;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final startLabel =
        '${rangeStart.hour.toString().padLeft(2, '0')}:'
        '${rangeStart.minute.toString().padLeft(2, '0')}';
    final endLabel =
        '${rangeEnd.hour.toString().padLeft(2, '0')}:'
        '${rangeEnd.minute.toString().padLeft(2, '0')}';

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetHeader(
              context,
              colorScheme,
              textTheme,
              startLabel,
              endLabel,
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                itemCount: groupItems.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) =>
                    _buildSheetCard(context, ref, groupItems[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheetHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String startLabel,
    String endLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$startLabel \u2013 $endLabel',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${groupItems.length} turnos',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colorScheme.outlineVariant, height: 1),
        ],
      ),
    );
  }

  Widget _buildSheetCard(
    BuildContext context,
    WidgetRef ref,
    DayScheduleItem item,
  ) {
    return switch (item) {
      RealDayItem() => TodayAppointmentCard(
          appointment: item.appointment,
          inTimeline: false,
          showEstimatedBadge: item.appointment.endTime == null,
          width: null,
        ),
      ProjectedDayItem() => _SheetProjectedCard(
          item: item,
          providerId: providerId,
        ),
    };
  }
}

/// Resolves patient name for a [ProjectedDayItem] inside the overflow sheet.
class _SheetProjectedCard extends ConsumerWidget {
  const _SheetProjectedCard({
    required this.item,
    required this.providerId,
  });

  final ProjectedDayItem item;
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider(providerId));
    final patientName = patientsAsync.valueOrNull
        ?.where((p) => p.id == item.rule.patientId)
        .firstOrNull
        ?.name;

    final dateKey =
        '${item.projectedStart.year}-'
        '${item.projectedStart.month.toString().padLeft(2, '0')}-'
        '${item.projectedStart.day.toString().padLeft(2, '0')}';

    return ProjectedAppointmentCard(
      rule: item.rule,
      patientName: patientName,
      providerId: providerId,
      dateKey: dateKey,
    );
  }
}

// ── Molecule: real appointment card wrapper ───────────────────────────────────

class _RealItemCard extends ConsumerWidget {
  const _RealItemCard({required this.item, required this.providerId});

  final RealDayItem item;
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEstimatedEnd = item.appointment.endTime == null;
    return TodayAppointmentCard(
      appointment: item.appointment,
      inTimeline: true,
      showEstimatedBadge: hasEstimatedEnd,
    );
  }
}

// ── Molecule: projected appointment card wrapper ──────────────────────────────

class _ProjectedItemCard extends ConsumerWidget {
  const _ProjectedItemCard({required this.item, required this.providerId});

  final ProjectedDayItem item;
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider(providerId));
    final patientName = patientsAsync.valueOrNull
        ?.where((p) => p.id == item.rule.patientId)
        .firstOrNull
        ?.name;

    final dateKey =
        '${item.projectedStart.year}-'
        '${item.projectedStart.month.toString().padLeft(2, '0')}-'
        '${item.projectedStart.day.toString().padLeft(2, '0')}';

    return ProjectedAppointmentCard(
      rule: item.rule,
      patientName: patientName,
      providerId: providerId,
      dateKey: dateKey,
    );
  }
}

// ── Range helpers ─────────────────────────────────────────────────────────────

int _computeRangeStartHour(List<DayScheduleItem> items) {
  const defaultStart = 7;
  if (items.isEmpty) return defaultStart;
  final earliest = items
      .map((i) => i.startTime.hour)
      .reduce((a, b) => a < b ? a : b);
  // 30min buffer, floor to hour
  final withBuffer = (earliest - 1).clamp(0, 23);
  return withBuffer < defaultStart ? withBuffer : defaultStart;
}

int _computeRangeEndHour(List<DayScheduleItem> items) {
  const defaultEnd = 22;
  if (items.isEmpty) return defaultEnd;
  final latest = items.map((i) {
    final endH = i.endTime.hour;
    final endM = i.endTime.minute;
    return endM > 0 ? endH + 1 : endH;
  }).reduce((a, b) => a > b ? a : b);
  // 30min buffer, ceil to hour
  final withBuffer = (latest + 1).clamp(0, 24);
  return withBuffer > defaultEnd ? withBuffer : defaultEnd;
}

int _computeRangeStart(List<DayScheduleItem> items) =>
    _computeRangeStartHour(items) * 60;

// ── Skeleton placeholder ──────────────────────────────────────────────────────

/// Shows three skeleton blocks at representative hours (08:00, 09:30, 11:00).
class DayTimelineSkeleton extends StatelessWidget {
  const DayTimelineSkeleton({super.key});

  static const _positions = [
    (hour: 8, minute: 0),
    (hour: 9, minute: 30),
    (hour: 11, minute: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const rangeStart = 7 * 60;

    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: TimeAxisColumn.columnWidth),
            Expanded(
              child: SizedBox(
                height: 15 * 60 * _kPixelsPerMinute,
                child: Stack(
                  children: [
                    for (final pos in _positions)
                      Positioned(
                        top:
                            (pos.hour * 60 + pos.minute - rangeStart) *
                            _kPixelsPerMinute,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
