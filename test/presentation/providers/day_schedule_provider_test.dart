// ignore_for_file: avoid_redundant_argument_values
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/day_schedule_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [assignColumns] and [projectRecurringToDate].
///
/// These tests are written in RED phase — the implementation does not exist yet.
void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  Appointment _apt({
    required String id,
    required DateTime start,
    DateTime? end,
    String? recurringId,
  }) {
    return Appointment(
      id: id,
      patientId: 'p1',
      providerId: 'prov1',
      date: start,
      concept: 'Consulta',
      totalAmount: 5000,
      endTime: end,
      recurringAppointmentId: recurringId,
    );
  }

  RecurringAppointment _rule({
    required String id,
    required Frequency frequency,
    required DateTime baseDate,
    bool active = true,
    DateTime? endDate,
    int? durationMinutes = 45,
  }) {
    return RecurringAppointment(
      id: id,
      patientId: 'p1',
      providerId: 'prov1',
      concept: 'Sesion',
      defaultAmount: 5000,
      frequency: frequency,
      baseDate: baseDate,
      active: active,
      endDate: endDate,
      defaultSessionDurationMinutes: durationMinutes,
    );
  }

  // ── assignColumns ──────────────────────────────────────────────────────────

  group('assignColumns', () {
    test('empty list returns empty', () {
      final result = assignColumns([]);
      expect(result, isEmpty);
    });

    test('single item — col=0, cols=1', () {
      final apt = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 45),
      );
      final items = [RealDayItem(appointment: apt, fallbackDurationMinutes: 45)];
      final result = assignColumns(items);

      expect(result.length, 1);
      expect(result.first.col, 0);
      expect(result.first.cols, 1);
    });

    test('no overlap — two items, each col=0, cols=1', () {
      final a1 = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 45),
      );
      final a2 = _apt(
        id: 'a2',
        start: DateTime(2025, 3, 10, 10, 0),
        end: DateTime(2025, 3, 10, 10, 45),
      );
      final items = [
        RealDayItem(appointment: a1, fallbackDurationMinutes: 45),
        RealDayItem(appointment: a2, fallbackDurationMinutes: 45),
      ];
      final result = assignColumns(items);

      expect(result.length, 2);
      expect(result[0].col, 0);
      expect(result[0].cols, 1);
      expect(result[1].col, 0);
      expect(result[1].cols, 1);
    });

    test('partial overlap — two items, cols=2 each', () {
      // a1: 09:00–09:45, a2: 09:30–10:15 (overlap 09:30–09:45)
      final a1 = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 45),
      );
      final a2 = _apt(
        id: 'a2',
        start: DateTime(2025, 3, 10, 9, 30),
        end: DateTime(2025, 3, 10, 10, 15),
      );
      final items = [
        RealDayItem(appointment: a1, fallbackDurationMinutes: 45),
        RealDayItem(appointment: a2, fallbackDurationMinutes: 45),
      ];
      final result = assignColumns(items);

      expect(result.length, 2);
      final cols0 = result.where((r) => r.col == 0).toList();
      final cols1 = result.where((r) => r.col == 1).toList();
      expect(cols0.length, 1);
      expect(cols1.length, 1);
      for (final r in result) {
        expect(r.cols, 2);
      }
    });

    test('full overlap (same slot) — two items, col 0 and 1, cols=2', () {
      final a1 = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 45),
      );
      final a2 = _apt(
        id: 'a2',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 45),
      );
      final items = [
        RealDayItem(appointment: a1, fallbackDurationMinutes: 45),
        RealDayItem(appointment: a2, fallbackDurationMinutes: 45),
      ];
      final result = assignColumns(items);

      expect(result.length, 2);
      final sortedCols = result.map((r) => r.col).toList()..sort();
      expect(sortedCols, [0, 1]);
      for (final r in result) {
        expect(r.cols, 2);
      }
    });

    test('four simultaneous — capped at 3 columns, fourth item col=2', () {
      final items = List.generate(4, (i) {
        final apt = _apt(
          id: 'a$i',
          start: DateTime(2025, 3, 10, 9, 0),
          end: DateTime(2025, 3, 10, 9, 45),
        );
        return RealDayItem(appointment: apt, fallbackDurationMinutes: 45);
      });
      final result = assignColumns(items);

      expect(result.length, 4);
      for (final r in result) {
        expect(r.cols, 3);
        expect(r.col, lessThanOrEqualTo(2));
      }
      // Exactly cols 0,1,2 assigned to first 3; 4th capped at 2
      final assignedCols = result.map((r) => r.col).toList()..sort();
      expect(assignedCols[0], 0);
      expect(assignedCols[1], 1);
      expect(assignedCols[2], 2);
      expect(assignedCols[3], 2); // capped
    });
  });

  // ── projectRecurringToDate ─────────────────────────────────────────────────

  group('projectRecurringToDate', () {
    // Base date: Monday 2025-03-03 at 09:00
    final baseDate = DateTime(2025, 3, 3, 9, 0);

    group('weekly', () {
      final rule = _rule(
        id: 'r1',
        frequency: Frequency.weekly,
        baseDate: baseDate,
      );

      test('projects correctly on same weekday 1 week later', () {
        final target = DateTime(2025, 3, 10);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNotNull);
        expect(result!.hour, 9);
        expect(result.minute, 0);
        expect(result.year, 2025);
        expect(result.month, 3);
        expect(result.day, 10);
      });

      test('projects correctly 2 weeks later', () {
        final target = DateTime(2025, 3, 17);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNotNull);
      });

      test('returns null when daysDiff % 7 != 0', () {
        final target = DateTime(2025, 3, 11); // Tuesday, 8 days after
        final result = projectRecurringToDate(rule, target);
        expect(result, isNull);
      });

      test('returns null when date < baseDate', () {
        final target = DateTime(2025, 2, 24); // 1 week before baseDate
        final result = projectRecurringToDate(rule, target);
        expect(result, isNull);
      });

      test('projects correctly on baseDate itself', () {
        final result = projectRecurringToDate(rule, baseDate);
        expect(result, isNotNull);
      });
    });

    group('biweekly', () {
      final rule = _rule(
        id: 'r2',
        frequency: Frequency.biweekly,
        baseDate: baseDate,
      );

      test('projects correctly 2 weeks later (14 days)', () {
        final target = DateTime(2025, 3, 17);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNotNull);
        expect(result!.hour, 9);
      });

      test('returns null 1 week later (7 days — not biweekly)', () {
        final target = DateTime(2025, 3, 10);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNull);
      });

      test('returns null when date < baseDate', () {
        final target = DateTime(2025, 2, 17);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNull);
      });
    });

    group('monthly', () {
      // Base: 2025-03-05 at 14:30
      final monthlyBase = DateTime(2025, 3, 5, 14, 30);
      final rule = _rule(
        id: 'r3',
        frequency: Frequency.monthly,
        baseDate: monthlyBase,
      );

      test('projects correctly on same day of month next month', () {
        final target = DateTime(2025, 4, 5);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNotNull);
        expect(result!.hour, 14);
        expect(result.minute, 30);
        expect(result.day, 5);
      });

      test('returns null on different day of month', () {
        final target = DateTime(2025, 4, 6);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNull);
      });

      test('returns null when target < baseDate (same day earlier month)', () {
        final target = DateTime(2025, 2, 5);
        final result = projectRecurringToDate(rule, target);
        expect(result, isNull);
      });

      test('projects correctly on baseDate itself', () {
        final result = projectRecurringToDate(rule, monthlyBase);
        expect(result, isNotNull);
      });
    });

    group('inactive rule', () {
      test('returns null regardless of frequency', () {
        final inactiveRule = _rule(
          id: 'r4',
          frequency: Frequency.weekly,
          baseDate: baseDate,
          active: false,
        );
        final target = DateTime(2025, 3, 10);
        final result = projectRecurringToDate(inactiveRule, target);
        expect(result, isNull);
      });
    });

    group('endDate constraint', () {
      test('returns null when target > endDate', () {
        final rule = _rule(
          id: 'r5',
          frequency: Frequency.weekly,
          baseDate: baseDate,
          endDate: DateTime(2025, 3, 12),
        );
        final target = DateTime(2025, 3, 17); // after endDate
        final result = projectRecurringToDate(rule, target);
        expect(result, isNull);
      });

      test('returns projected time when target < endDate', () {
        final rule = _rule(
          id: 'r6',
          frequency: Frequency.weekly,
          baseDate: baseDate,
          endDate: DateTime(2025, 3, 20),
        );
        final target = DateTime(2025, 3, 10); // before endDate
        final result = projectRecurringToDate(rule, target);
        expect(result, isNotNull);
      });
    });
  });
}
