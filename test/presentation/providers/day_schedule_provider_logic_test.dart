// ignore_for_file: avoid_redundant_argument_values
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/day_schedule_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the day-schedule filtering and deduplication logic.
///
/// These tests exercise [buildDaySchedule] — a pure function that merges
/// real appointments and recurring projections, deduplicating projected items
/// that already have a real appointment for that day.
///
/// Written in RED phase — [buildDaySchedule] does not exist yet.
void main() {
  final targetDate = DateTime(2025, 3, 10); // Monday

  // ── Helpers ────────────────────────────────────────────────────────────────

  Appointment _apt({
    required String id,
    required DateTime start,
    DateTime? end,
    String? recurringId,
    AppointmentStatus status = AppointmentStatus.unpaid,
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
      status: status,
    );
  }

  RecurringAppointment _rule({
    required String id,
    required Frequency frequency,
    required DateTime baseDate,
    bool active = true,
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
      defaultSessionDurationMinutes: 45,
    );
  }

  // Monday base — weekly rule will project to every Monday
  final weeklyBase = DateTime(2025, 3, 3, 9, 0); // Monday 2025-03-03 09:00
  // targetDate = Monday 2025-03-10 → daysDiff = 7 → weekly match

  group('buildDaySchedule', () {
    test('empty day — returns empty list', () {
      final result = buildDaySchedule(
        appointments: [],
        recurringRules: [],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(result, isEmpty);
    });

    test('only real appointments — returns RealDayItems', () {
      final apt = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 45),
      );
      final result = buildDaySchedule(
        appointments: [apt],
        recurringRules: [],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(result.length, 1);
      expect(result.first, isA<RealDayItem>());
      final item = result.first as RealDayItem;
      expect(item.appointment.id, 'a1');
    });

    test('only projected recurring — returns ProjectedDayItems', () {
      final rule = _rule(
        id: 'r1',
        frequency: Frequency.weekly,
        baseDate: weeklyBase,
      );
      final result = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(result.length, 1);
      expect(result.first, isA<ProjectedDayItem>());
      final item = result.first as ProjectedDayItem;
      expect(item.rule.id, 'r1');
    });

    test('mix: recurring + real with matching recurringAppointmentId — deduplicates projected', () {
      final rule = _rule(
        id: 'r1',
        frequency: Frequency.weekly,
        baseDate: weeklyBase,
      );
      // Real appointment linked to the recurring rule
      final apt = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 45),
        recurringId: 'r1',
      );

      final result = buildDaySchedule(
        appointments: [apt],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      // Should have only the real item — projected is deduped
      expect(result.length, 1);
      expect(result.first, isA<RealDayItem>());
    });

    test('mix: recurring + real with no recurringId — keeps both', () {
      final rule = _rule(
        id: 'r1',
        frequency: Frequency.weekly,
        baseDate: weeklyBase,
      );
      // Real appointment NOT linked to any recurring rule
      final apt = _apt(
        id: 'a2',
        start: DateTime(2025, 3, 10, 10, 0),
        end: DateTime(2025, 3, 10, 10, 45),
        recurringId: null,
      );

      final result = buildDaySchedule(
        appointments: [apt],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      // Should have both: projected r1 + real a2
      expect(result.length, 2);
      expect(result.whereType<RealDayItem>().length, 1);
      expect(result.whereType<ProjectedDayItem>().length, 1);
    });

    test('filters out appointments not on target date', () {
      final wrongDayApt = _apt(
        id: 'a3',
        start: DateTime(2025, 3, 11, 9, 0), // Tuesday — different day
        end: DateTime(2025, 3, 11, 9, 45),
      );
      final result = buildDaySchedule(
        appointments: [wrongDayApt],
        recurringRules: [],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(result, isEmpty);
    });

    test('cancelled appointments are excluded', () {
      final cancelledApt = _apt(
        id: 'a4',
        start: DateTime(2025, 3, 10, 9, 0),
        status: AppointmentStatus.cancelled,
      );
      final result = buildDaySchedule(
        appointments: [cancelledApt],
        recurringRules: [],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(result, isEmpty);
    });

    test('RealDayItem endTime uses appointment.endTime when set', () {
      final apt = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: DateTime(2025, 3, 10, 9, 30),
      );
      final result = buildDaySchedule(
        appointments: [apt],
        recurringRules: [],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      final item = result.first as RealDayItem;
      expect(item.endTime, DateTime(2025, 3, 10, 9, 30));
    });

    test('RealDayItem endTime uses fallback when appointment.endTime is null', () {
      final apt = _apt(
        id: 'a1',
        start: DateTime(2025, 3, 10, 9, 0),
        end: null,
      );
      final result = buildDaySchedule(
        appointments: [apt],
        recurringRules: [],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      final item = result.first as RealDayItem;
      // fallback = providerDefaultDurationMinutes = 45
      expect(item.endTime, DateTime(2025, 3, 10, 9, 45));
    });

    test('ProjectedDayItem endTime uses rule.defaultSessionDurationMinutes when set', () {
      final rule = RecurringAppointment(
        id: 'r1',
        patientId: 'p1',
        providerId: 'prov1',
        concept: 'Sesion',
        defaultAmount: 5000,
        frequency: Frequency.weekly,
        baseDate: weeklyBase,
        active: true,
        defaultSessionDurationMinutes: 60,
      );
      final result = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      final item = result.first as ProjectedDayItem;
      // 09:00 + 60min = 10:00
      expect(item.endTime.hour, 10);
      expect(item.endTime.minute, 0);
    });

    test('ProjectedDayItem uses providerDefault when rule duration is null', () {
      final rule = RecurringAppointment(
        id: 'r1',
        patientId: 'p1',
        providerId: 'prov1',
        concept: 'Sesion',
        defaultAmount: 5000,
        frequency: Frequency.weekly,
        baseDate: weeklyBase,
        active: true,
        defaultSessionDurationMinutes: null,
      );
      final result = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 30,
      );

      final item = result.first as ProjectedDayItem;
      // 09:00 + 30min = 09:30
      expect(item.endTime.hour, 9);
      expect(item.endTime.minute, 30);
    });
  });
}
