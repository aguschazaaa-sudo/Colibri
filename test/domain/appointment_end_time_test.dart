// 🧪 RED phase — these tests fail until the feature is implemented.
// Tests for: Appointment.endTime, Appointment.duration getter,
// and AppointmentOverlapChecker.findOverlaps.

import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/appointment_overlap_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseDate = DateTime(2025, 6, 15, 10, 0); // 10:00

  Appointment makeAppointment({
    String id = 'a1',
    String patientId = 'p1',
    String providerId = 'prov1',
    DateTime? date,
    DateTime? endTime,
    AppointmentStatus status = AppointmentStatus.unpaid,
  }) {
    return Appointment(
      id: id,
      patientId: patientId,
      providerId: providerId,
      date: date ?? baseDate,
      concept: 'Consulta',
      totalAmount: 1000,
      endTime: endTime,
      status: status,
    );
  }

  group('Appointment.endTime field', () {
    test('endTime is null by default (backward compatible)', () {
      final appointment = makeAppointment();
      expect(appointment.endTime, isNull);
    });

    test('duration is null when endTime is not set', () {
      final appointment = makeAppointment();
      expect(appointment.duration, isNull);
    });

    test('duration returns correct Duration when endTime is set', () {
      final end = baseDate.add(const Duration(hours: 1));
      final appointment = makeAppointment(endTime: end);
      expect(appointment.duration, const Duration(hours: 1));
    });

    test('duration returns correct Duration for 30-minute appointment', () {
      final end = baseDate.add(const Duration(minutes: 30));
      final appointment = makeAppointment(endTime: end);
      expect(appointment.duration, const Duration(minutes: 30));
    });

    test('copyWith preserves endTime', () {
      final end = baseDate.add(const Duration(hours: 1));
      final appointment = makeAppointment(endTime: end);
      final copied = appointment.copyWith(concept: 'Nueva consulta');
      expect(copied.endTime, end);
      expect(copied.concept, 'Nueva consulta');
    });

    test('copyWith can override endTime', () {
      final end1 = baseDate.add(const Duration(hours: 1));
      final end2 = baseDate.add(const Duration(hours: 2));
      final appointment = makeAppointment(endTime: end1);
      final copied = appointment.copyWith(endTime: end2);
      expect(copied.endTime, end2);
    });

    test('copyWith can clear endTime to null', () {
      final end = baseDate.add(const Duration(hours: 1));
      final appointment = makeAppointment(endTime: end);
      // Freezed copyWith with null requires using the nullable override pattern
      final copied = appointment.copyWith(endTime: null);
      expect(copied.endTime, isNull);
    });

    test('two appointments with same fields but different endTime are not equal', () {
      final end1 = baseDate.add(const Duration(hours: 1));
      final end2 = baseDate.add(const Duration(hours: 2));
      final a1 = makeAppointment(endTime: end1);
      final a2 = makeAppointment(endTime: end2);
      expect(a1, isNot(equals(a2)));
    });
  });

  group('AppointmentOverlapChecker.findOverlaps', () {
    // Scenario: existing appointments on the day
    // newAppointment starts at 10:00

    test('no overlaps when list is empty', () {
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: [],
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, isEmpty);
    });

    test('overlaps when both have endTime and intervals intersect', () {
      // existing: 09:30 – 10:30, new: 10:00 – 11:00 → overlap
      final existing = [
        makeAppointment(
          id: 'existing1',
          patientId: 'p2',
          date: baseDate.subtract(const Duration(minutes: 30)),
          endTime: baseDate.add(const Duration(minutes: 30)),
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, hasLength(1));
      expect(overlaps.first.id, 'existing1');
    });

    test('no overlap when both have endTime and intervals do NOT intersect', () {
      // existing: 08:00 – 09:00, new: 10:00 – 11:00 → no overlap
      final existing = [
        makeAppointment(
          id: 'existing1',
          patientId: 'p2',
          date: DateTime(2025, 6, 15, 8, 0),
          endTime: DateTime(2025, 6, 15, 9, 0),
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, isEmpty);
    });

    test('no overlap when intervals are adjacent (end == start)', () {
      // existing: 09:00 – 10:00, new: 10:00 – 11:00 → [start1, end1) is half-open, no overlap
      final existing = [
        makeAppointment(
          id: 'existing1',
          patientId: 'p2',
          date: DateTime(2025, 6, 15, 9, 0),
          endTime: DateTime(2025, 6, 15, 10, 0),
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, isEmpty);
    });

    test('existing without endTime: overlaps when start times are exactly equal', () {
      // existing: 10:00 (no endTime), new starts at 10:00 → overlap
      final existing = [
        makeAppointment(
          id: 'existing1',
          patientId: 'p2',
          date: baseDate,
          endTime: null,
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, hasLength(1));
    });

    test('existing without endTime: no overlap when start times differ', () {
      // existing: 09:00 (no endTime), new starts at 10:00 → no overlap
      final existing = [
        makeAppointment(
          id: 'existing1',
          patientId: 'p2',
          date: DateTime(2025, 6, 15, 9, 0),
          endTime: null,
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: null,
        newPatientId: 'p1',
      );
      expect(overlaps, isEmpty);
    });

    test('excludes self by appointmentId (edit mode)', () {
      // When editing, should not report self as overlap
      final existing = [
        makeAppointment(
          id: 'self',
          patientId: 'p1',
          date: baseDate,
          endTime: baseDate.add(const Duration(hours: 1)),
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
        excludeAppointmentId: 'self',
      );
      expect(overlaps, isEmpty);
    });

    test('same patientId overlap is included (major warning)', () {
      // Overlap with same patient → should be present in results
      final existing = [
        makeAppointment(
          id: 'existing1',
          patientId: 'p1', // same patient
          date: baseDate,
          endTime: baseDate.add(const Duration(hours: 1)),
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, hasLength(1));
      expect(overlaps.first.patientId, 'p1');
    });

    test('different patientId overlap is also included (minor warning)', () {
      final existing = [
        makeAppointment(
          id: 'existing1',
          patientId: 'p2', // different patient
          date: baseDate,
          endTime: baseDate.add(const Duration(hours: 1)),
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, hasLength(1));
      expect(overlaps.first.patientId, 'p2');
    });

    test('cancelled appointments are excluded from overlap check', () {
      final existing = [
        makeAppointment(
          id: 'cancelled1',
          patientId: 'p2',
          date: baseDate,
          endTime: baseDate.add(const Duration(hours: 1)),
          status: AppointmentStatus.cancelled,
        ),
      ];
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, isEmpty);
    });

    test('multiple overlapping appointments are all returned', () {
      final existing = [
        makeAppointment(
          id: 'e1',
          patientId: 'p2',
          date: DateTime(2025, 6, 15, 9, 30),
          endTime: DateTime(2025, 6, 15, 10, 30),
        ),
        makeAppointment(
          id: 'e2',
          patientId: 'p3',
          date: DateTime(2025, 6, 15, 10, 30),
          endTime: DateTime(2025, 6, 15, 11, 30),
        ),
        makeAppointment(
          id: 'e3',
          patientId: 'p4',
          date: DateTime(2025, 6, 15, 12, 0),
          endTime: DateTime(2025, 6, 15, 13, 0),
        ),
      ];
      // new: 10:00 – 11:00 overlaps with e1 (9:30–10:30) and e2 (10:30–11:30)
      // but NOT e3 (12:00–13:00)
      final overlaps = AppointmentOverlapChecker.findOverlaps(
        existing: existing,
        newStart: baseDate,
        newEnd: baseDate.add(const Duration(hours: 1)),
        newPatientId: 'p1',
      );
      expect(overlaps, hasLength(2));
      expect(overlaps.map((a) => a.id), containsAll(['e1', 'e2']));
    });
  });
}
