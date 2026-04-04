import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/day_schedule_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecurringAppointment makeRule({
    required String id,
    required DateTime baseDate,
    Frequency frequency = Frequency.weekly,
    List<String> cancelledDates = const [],
  }) {
    return RecurringAppointment(
      id: id,
      patientId: 'p1',
      providerId: 'prov1',
      concept: 'Sesion',
      defaultAmount: 5000,
      frequency: frequency,
      baseDate: baseDate,
      active: true,
      cancelledDates: cancelledDates,
    );
  }

  final targetDate = DateTime(2026, 4, 10); // Friday
  const targetDateKey = '2026-04-10';

  group('buildDaySchedule — cancelledDates filtering', () {
    test('suppresses ghost card when dateKey is in cancelledDates', () {
      final rule = makeRule(
        id: 'rec1',
        baseDate: DateTime(2026, 3, 13, 9, 0), // same weekday (Friday)
        cancelledDates: [targetDateKey],
      );

      final items = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(items, isEmpty);
    });

    test('generates ghost card when dateKey is NOT in cancelledDates', () {
      final rule = makeRule(
        id: 'rec1',
        baseDate: DateTime(2026, 3, 13, 9, 0),
        cancelledDates: [],
      );

      final items = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(items.length, 1);
      expect(items.first, isA<ProjectedDayItem>());
    });

    test('handles rule with no cancelledDates field (empty list default)', () {
      // RecurringAppointment with default cancelledDates = []
      final rule = RecurringAppointment(
        id: 'rec2',
        patientId: 'p1',
        providerId: 'prov1',
        concept: 'Sesion',
        defaultAmount: 5000,
        frequency: Frequency.weekly,
        baseDate: DateTime(2026, 3, 13, 9, 0),
        active: true,
        // cancelledDates not specified — defaults to []
      );

      final items = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(items.length, 1);
      expect(items.first, isA<ProjectedDayItem>());
    });

    test('only suppresses the specific cancelled date, not other dates', () {
      final rule = makeRule(
        id: 'rec1',
        baseDate: DateTime(2026, 3, 13, 9, 0),
        cancelledDates: [targetDateKey],
      );

      final otherDate = DateTime(2026, 4, 17);

      final itemsOnCancelledDate = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      final itemsOnOtherDate = buildDaySchedule(
        appointments: [],
        recurringRules: [rule],
        date: otherDate,
        providerDefaultDurationMinutes: 45,
      );

      expect(itemsOnCancelledDate, isEmpty);
      expect(itemsOnOtherDate.length, 1);
    });

    test('real appointment for a cancelled date is still shown (real trumps cancellation)', () {
      // If the provider somehow has a real appointment on a cancelled date,
      // the real appointment still appears (cancellation only suppresses ghosts).
      final rule = makeRule(
        id: 'rec1',
        baseDate: DateTime(2026, 3, 13, 9, 0),
        cancelledDates: [targetDateKey],
      );

      final realAppointment = Appointment(
        id: 'apt1',
        patientId: 'p1',
        providerId: 'prov1',
        concept: 'Sesion',
        totalAmount: 5000,
        date: DateTime(2026, 4, 10, 9, 0),
        recurringAppointmentId: 'rec1',
      );

      final items = buildDaySchedule(
        appointments: [realAppointment],
        recurringRules: [rule],
        date: targetDate,
        providerDefaultDurationMinutes: 45,
      );

      // Real item present; ghost suppressed (covered by recurringId + cancelledDates)
      expect(items.length, 1);
      expect(items.first, isA<RealDayItem>());
    });
  });
}
