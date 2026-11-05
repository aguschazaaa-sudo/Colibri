// Tests for AC1, AC2: RecurringAppointment entity and RecurringAppointmentModel
// serialization with defaultSessionDurationMinutes field.
//
// These tests are written RED-first — they will fail until the feature is implemented.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/data/models/recurring_appointment_model.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseDate = DateTime(2024, 3, 15, 10, 0);
  final baseTimestamp = Timestamp.fromDate(baseDate);

  group('RecurringAppointment entity — defaultSessionDurationMinutes', () {
    test('AC1: entity can be constructed with a duration value', () {
      final entity = RecurringAppointment(
        id: 'r1',
        patientId: 'pat1',
        providerId: 'prov1',
        concept: 'Consulta',
        defaultAmount: 5000,
        frequency: Frequency.monthly,
        baseDate: baseDate,
        defaultSessionDurationMinutes: 60,
      );

      expect(entity.defaultSessionDurationMinutes, 60);
    });

    test('AC1: entity defaults defaultSessionDurationMinutes to null', () {
      final entity = RecurringAppointment(
        id: 'r1',
        patientId: 'pat1',
        providerId: 'prov1',
        concept: 'Consulta',
        defaultAmount: 5000,
        frequency: Frequency.monthly,
        baseDate: baseDate,
      );

      expect(entity.defaultSessionDurationMinutes, isNull);
    });

    test('AC1: copyWith preserves duration when not overridden', () {
      final entity = RecurringAppointment(
        id: 'r1',
        patientId: 'pat1',
        providerId: 'prov1',
        concept: 'Consulta',
        defaultAmount: 5000,
        frequency: Frequency.monthly,
        baseDate: baseDate,
        defaultSessionDurationMinutes: 45,
      );

      final copy = entity.copyWith(concept: 'Otra Consulta');
      expect(copy.defaultSessionDurationMinutes, 45);
    });
  });

  group('RecurringAppointmentModel serialization — defaultSessionDurationMinutes', () {
    test('AC2: fromJson reads defaultSessionDurationMinutes when present', () {
      final json = <String, dynamic>{
        'patientId': 'pat1',
        'providerId': 'prov1',
        'concept': 'Consulta',
        'defaultAmount': 5000.0,
        'frequency': 'monthly',
        'baseDate': baseTimestamp,
        'active': true,
        'defaultSessionDurationMinutes': 50,
      };

      final model = RecurringAppointmentModel.fromJson(json, 'r1');
      expect(model.defaultSessionDurationMinutes, 50);
    });

    test('AC2: fromJson returns null for defaultSessionDurationMinutes when absent', () {
      final json = <String, dynamic>{
        'patientId': 'pat1',
        'providerId': 'prov1',
        'concept': 'Consulta',
        'defaultAmount': 5000.0,
        'frequency': 'monthly',
        'baseDate': baseTimestamp,
        'active': true,
        // defaultSessionDurationMinutes absent — legacy record
      };

      final model = RecurringAppointmentModel.fromJson(json, 'r1');
      expect(model.defaultSessionDurationMinutes, isNull);
    });

    test('AC2: toJson omits defaultSessionDurationMinutes when null', () {
      final model = RecurringAppointmentModel(
        id: 'r1',
        patientId: 'pat1',
        providerId: 'prov1',
        concept: 'Consulta',
        defaultAmount: 5000,
        frequency: Frequency.monthly,
        baseDate: baseDate,
        active: true,
        defaultSessionDurationMinutes: null,
      );

      final json = model.toJson();
      expect(json.containsKey('defaultSessionDurationMinutes'), isFalse);
    });

    test('AC2: toJson includes defaultSessionDurationMinutes when set', () {
      final model = RecurringAppointmentModel(
        id: 'r1',
        patientId: 'pat1',
        providerId: 'prov1',
        concept: 'Consulta',
        defaultAmount: 5000,
        frequency: Frequency.monthly,
        baseDate: baseDate,
        active: true,
        defaultSessionDurationMinutes: 90,
      );

      final json = model.toJson();
      expect(json['defaultSessionDurationMinutes'], 90);
    });

    test('AC2: fromEntity maps duration from entity to model', () {
      final entity = RecurringAppointment(
        id: 'r1',
        patientId: 'pat1',
        providerId: 'prov1',
        concept: 'Consulta',
        defaultAmount: 5000,
        frequency: Frequency.monthly,
        baseDate: baseDate,
        defaultSessionDurationMinutes: 75,
      );

      final model = RecurringAppointmentModel.fromEntity(entity);
      expect(model.defaultSessionDurationMinutes, 75);
    });

    test('AC2: toEntity maps duration from model to entity', () {
      final model = RecurringAppointmentModel(
        id: 'r1',
        patientId: 'pat1',
        providerId: 'prov1',
        concept: 'Consulta',
        defaultAmount: 5000,
        frequency: Frequency.monthly,
        baseDate: baseDate,
        active: true,
        defaultSessionDurationMinutes: 30,
      );

      final entity = model.toEntity();
      expect(entity.defaultSessionDurationMinutes, 30);
    });

    test('AC2: round-trip fromJson → toJson preserves duration', () {
      final json = <String, dynamic>{
        'patientId': 'pat1',
        'providerId': 'prov1',
        'concept': 'Consulta',
        'defaultAmount': 5000.0,
        'frequency': 'weekly',
        'baseDate': baseTimestamp,
        'active': true,
        'defaultSessionDurationMinutes': 120,
      };

      final model = RecurringAppointmentModel.fromJson(json, 'r1');
      final roundTripped = model.toJson();

      expect(roundTripped['defaultSessionDurationMinutes'], 120);
    });
  });
}
