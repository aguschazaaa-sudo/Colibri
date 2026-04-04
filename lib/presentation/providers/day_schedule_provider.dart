import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/provider_profile_provider.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_schedule_provider.g.dart';

// ── Domain models ─────────────────────────────────────────────────────────────

/// A scheduled item that appears on the day timeline — either a confirmed
/// [Appointment] or a projected occurrence derived from a [RecurringAppointment].
sealed class DayScheduleItem {
  DateTime get startTime;
  DateTime get endTime;
}

/// A confirmed [Appointment] on the timeline.
class RealDayItem extends DayScheduleItem {
  RealDayItem({
    required this.appointment,
    required this.fallbackDurationMinutes,
  });

  final Appointment appointment;

  /// Duration used when [appointment.endTime] is null.
  final int fallbackDurationMinutes;

  @override
  DateTime get startTime => appointment.date;

  @override
  DateTime get endTime =>
      appointment.endTime ??
      appointment.date.add(Duration(minutes: fallbackDurationMinutes));
}

/// A projected occurrence of a [RecurringAppointment] that has no confirmed
/// [Appointment] for the target date yet.
class ProjectedDayItem extends DayScheduleItem {
  ProjectedDayItem({
    required this.rule,
    required this.projectedStart,
    required this.durationMinutes,
  });

  final RecurringAppointment rule;
  final DateTime projectedStart;
  final int durationMinutes;

  @override
  DateTime get startTime => projectedStart;

  @override
  DateTime get endTime => projectedStart.add(Duration(minutes: durationMinutes));
}

// ── Layout model ──────────────────────────────────────────────────────────────

/// A [DayScheduleItem] enriched with column-layout information for rendering
/// overlapping appointments side-by-side.
class DayScheduleItemWithLayout {
  const DayScheduleItemWithLayout({
    required this.item,
    required this.col,
    required this.cols,
  });

  final DayScheduleItem item;

  /// 0-indexed column this item occupies within its overlap group.
  final int col;

  /// Total number of columns in this item's overlap group.
  final int cols;
}

// ── Pure functions ────────────────────────────────────────────────────────────

/// Projects [rule] onto [date] and returns the projected [DateTime] (with the
/// time component of [rule.baseDate]) if the rule fires on that date.
///
/// Returns `null` if:
/// - The rule is inactive.
/// - The date is before [rule.baseDate].
/// - The date is after [rule.endDate] (when set).
/// - The recurrence frequency does not align with [date].
DateTime? projectRecurringToDate(RecurringAppointment rule, DateTime date) {
  if (!rule.active) return null;

  final baseDateOnly = DateTime(
    rule.baseDate.year,
    rule.baseDate.month,
    rule.baseDate.day,
  );
  final targetDateOnly = DateTime(date.year, date.month, date.day);

  final daysDiff = targetDateOnly.difference(baseDateOnly).inDays;

  // Target must not be before baseDate
  if (daysDiff < 0) return null;

  // Must not exceed endDate
  if (rule.endDate != null) {
    final endDateOnly = DateTime(
      rule.endDate!.year,
      rule.endDate!.month,
      rule.endDate!.day,
    );
    if (targetDateOnly.isAfter(endDateOnly)) return null;
  }

  final projected = DateTime(
    date.year,
    date.month,
    date.day,
    rule.baseDate.hour,
    rule.baseDate.minute,
  );

  switch (rule.frequency) {
    case Frequency.weekly:
      return daysDiff % 7 == 0 ? projected : null;
    case Frequency.biweekly:
      return daysDiff % 14 == 0 ? projected : null;
    case Frequency.monthly:
      return date.day == rule.baseDate.day ? projected : null;
  }
}

/// Merges [appointments] and [recurringRules] for a given [date] into a
/// unified list of [DayScheduleItem]s.
///
/// - Excludes cancelled appointments.
/// - Excludes appointments not on [date].
/// - Deduplicates: if a recurring rule already has a real appointment with
///   matching [recurringAppointmentId] on [date], the projected item is skipped.
List<DayScheduleItem> buildDaySchedule({
  required List<Appointment> appointments,
  required List<RecurringAppointment> recurringRules,
  required DateTime date,
  required int providerDefaultDurationMinutes,
}) {
  // Filter real appointments for this day, excluding cancelled
  final dayAppointments = appointments
      .where(
        (a) =>
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day &&
            a.status != AppointmentStatus.cancelled,
      )
      .toList();

  // Collect recurring IDs already covered by a real appointment on this day
  final coveredRecurringIds = dayAppointments
      .where((a) => a.recurringAppointmentId != null)
      .map((a) => a.recurringAppointmentId!)
      .toSet();

  final items = <DayScheduleItem>[];

  // Add real items
  for (final apt in dayAppointments) {
    items.add(
      RealDayItem(
        appointment: apt,
        fallbackDurationMinutes: providerDefaultDurationMinutes,
      ),
    );
  }

  // Add projected items (deduplicated)
  for (final rule in recurringRules) {
    if (coveredRecurringIds.contains(rule.id)) continue;

    // Skip cancelled occurrences
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (rule.cancelledDates.contains(dateKey)) continue;

    final projected = projectRecurringToDate(rule, date);
    if (projected == null) continue;

    final duration =
        rule.defaultSessionDurationMinutes ?? providerDefaultDurationMinutes;

    items.add(
      ProjectedDayItem(
        rule: rule,
        projectedStart: projected,
        durationMinutes: duration,
      ),
    );
  }

  items.sort((a, b) => a.startTime.compareTo(b.startTime));
  return items;
}

/// Greedy column-assignment algorithm for overlapping [DayScheduleItem]s.
///
/// Sorts items by start time, then assigns each to the first available column
/// (where no existing item in that column overlaps). Caps at 3 columns; items
/// that would need a 4th column are placed in column 2.
///
/// Two items overlap if `a.startTime < b.endTime && b.startTime < a.endTime`.
List<DayScheduleItemWithLayout> assignColumns(List<DayScheduleItem> items) {
  if (items.isEmpty) return [];

  final sorted = [...items]..sort((a, b) => a.startTime.compareTo(b.startTime));

  // Each entry: the item placed in a given column (used to check future overlaps)
  const maxCols = 3;
  // columns[i] = list of items already assigned to column i
  final columns = <List<DayScheduleItem>>[];

  // Intermediate result tracking assignment
  final assignments = <DayScheduleItem, int>{};

  for (final item in sorted) {
    int assigned = -1;
    for (int col = 0; col < columns.length && col < maxCols - 1; col++) {
      final colItems = columns[col];
      final overlapsAny = colItems.any(
        (existing) =>
            item.startTime.isBefore(existing.endTime) &&
            existing.startTime.isBefore(item.endTime),
      );
      if (!overlapsAny) {
        assigned = col;
        colItems.add(item);
        break;
      }
    }

    if (assigned == -1) {
      if (columns.length < maxCols) {
        // Open a new column
        assigned = columns.length;
        columns.add([item]);
      } else {
        // Cap at maxCols - 1 (column index 2)
        assigned = maxCols - 1;
        columns[maxCols - 1].add(item);
      }
    }
    assignments[item] = assigned;
  }

  // Second pass: determine the total cols for each overlap group.
  // For simplicity, recalculate overlap groups.
  final result = <DayScheduleItemWithLayout>[];

  for (final item in sorted) {
    final col = assignments[item]!;

    // Find all items that overlap with this item to determine group size
    final overlapping = sorted
        .where(
          (other) =>
              other != item &&
              item.startTime.isBefore(other.endTime) &&
              other.startTime.isBefore(item.endTime),
        )
        .toList();

    // Max column used by any item in the overlap group (including self)
    final groupItems = [item, ...overlapping];
    final maxColInGroup = groupItems
        .map((i) => assignments[i] ?? 0)
        .reduce((a, b) => a > b ? a : b);

    final cols = maxColInGroup + 1;

    result.add(DayScheduleItemWithLayout(item: item, col: col, cols: cols));
  }

  return result;
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Watches all [RecurringAppointment]s for a provider across all patients.
@riverpod
Stream<List<RecurringAppointment>> allRecurringAppointments(
  Ref ref,
  String providerId,
) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.watchRecurringAppointments(
    providerId: providerId,
    patientId: '',
  );
}

/// Combines all appointments and recurring rules for [providerId] on [date],
/// returning a unified list of [DayScheduleItem]s.
///
/// Deduplicates projected items that already have a confirmed appointment.
@riverpod
AsyncValue<List<DayScheduleItem>> daySchedule(
  Ref ref, {
  required String providerId,
  required DateTime date,
}) {
  final appointmentsAsync = ref.watch(
    ledgerProvider(providerId: providerId, patientId: ''),
  );
  final recurringAsync = ref.watch(allRecurringAppointmentsProvider(providerId));
  final providerAsync = ref.watch(providerProfileProvider(providerId));

  // Propagate loading / error states
  if (appointmentsAsync.isLoading || recurringAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (appointmentsAsync.hasError) {
    return AsyncValue.error(
      appointmentsAsync.error!,
      appointmentsAsync.stackTrace!,
    );
  }
  if (recurringAsync.hasError) {
    return AsyncValue.error(
      recurringAsync.error!,
      recurringAsync.stackTrace!,
    );
  }

  final appointments = appointmentsAsync.valueOrNull ?? [];
  final recurringRules = recurringAsync.valueOrNull ?? [];
  final provider = providerAsync.valueOrNull;
  final defaultDuration = provider?.defaultSessionDurationMinutes ?? 45;

  return AsyncValue.data(
    buildDaySchedule(
      appointments: appointments,
      recurringRules: recurringRules,
      date: date,
      providerDefaultDurationMinutes: defaultDuration,
    ),
  );
}
