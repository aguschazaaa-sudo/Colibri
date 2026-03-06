import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/data/models/patient_model.dart';
import 'package:cobrador/data/models/appointment_model.dart';
import 'package:cobrador/data/models/payment_model.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/data/models/provider_model.dart';
import 'package:cobrador/domain/appointment.dart';

void main() {
  final now = DateTime(
    2023,
    1,
    1,
    10,
    0,
  ); // Fixed date for deterministic testing
  final timestamp = Timestamp.fromDate(now);

  group('ProviderModel Serialization', () {
    test('should map to/from JSON correctly with nonWorkingDays', () {
      final json = {
        'id': 'prov1',
        'email': 'test@test.com',
        'name': 'Test Provider',
        'subscriptionStatus': 'active',
        'plan': 'basic',
        'defaultMonthlyInterestRate': 0.05,
        'nonWorkingDays': ['05-25', '12-25'],
        'createdAt': timestamp,
      };

      final model = ProviderModel.fromJson(json);

      expect(model.id, 'prov1');
      expect(model.nonWorkingDays, ['05-25', '12-25']);
      expect(model.plan, SubscriptionPlan.basic);

      final reversedJson = model.toJson();
      expect(reversedJson['id'], 'prov1');
      expect(reversedJson['nonWorkingDays'], ['05-25', '12-25']);
      expect(reversedJson['createdAt'], timestamp);
    });

    test('should provide empty nonWorkingDays list if missing', () {
      final json = {
        'id': 'prov1',
        'email': 'test@test.com',
        'name': 'Test Provider',
        'subscriptionStatus': 'active',
        'plan': 'basic',
        'defaultMonthlyInterestRate': 0.05,
        'createdAt': timestamp,
      };

      final model = ProviderModel.fromJson(json);
      expect(model.nonWorkingDays, isEmpty);
    });
  });

  group('PatientModel Serialization', () {
    test('should map to/from JSON correctly', () {
      final json = {
        'providerId': 'prov1',
        'name': 'John Doe',
        'phoneNumber': '12345678',
        'totalDebt': 100.50,
        'balance': 20.0,
        'createdAt': timestamp,
      };

      final model = PatientModel.fromJson(json, 'pat1');

      expect(model.id, 'pat1');
      expect(model.name, 'John Doe');
      expect(model.balance, 20.0);
      expect(model.createdAt, now);

      final reversedJson = model.toJson();
      expect(reversedJson['providerId'], 'prov1');
      expect(reversedJson['totalDebt'], 100.50);
      expect(reversedJson['createdAt'], timestamp); // Must be Timestamp
    });

    test(
      'should handle missing balance gracefully (backward compatibility)',
      () {
        final json = {
          'providerId': 'prov1',
          'name': 'John Doe',
          'phoneNumber': '12345678',
          'totalDebt': 100.50,
          // no balance
          'createdAt': timestamp,
        };

        final model = PatientModel.fromJson(json, 'pat1');
        expect(model.balance, 0.0); // Defaults to 0
      },
    );
  });

  group('AppointmentModel Serialization', () {
    test('should map to/from JSON correctly', () {
      final json = {
        'patientId': 'pat1',
        'providerId': 'prov1',
        'date': timestamp,
        'concept': 'Terapia',
        'totalAmount': 5000.0,
        'amountPaid': 0.0,
        'status': 'unpaid',
      };

      final model = AppointmentModel.fromJson(json, 'app1');

      expect(model.id, 'app1');
      expect(model.concept, 'Terapia');
      expect(model.status, AppointmentStatus.unpaid);
      expect(model.date, now);

      final reversedJson = model.toJson();
      expect(reversedJson['totalAmount'], 5000.0);
      expect(reversedJson['status'], 'unpaid');
      expect(reversedJson['date'], timestamp);
    });
  });

  group('PaymentModel Serialization', () {
    test('should map to/from JSON correctly', () {
      final json = {
        'patientId': 'pat1',
        'providerId': 'prov1',
        'appointmentId': 'app1',
        'amount': 2500.0,
        'date': timestamp,
      };

      final model = PaymentModel.fromJson(json, 'pay1');

      expect(model.id, 'pay1');
      expect(model.amount, 2500.0);
      expect(model.appointmentId, 'app1');
      expect(model.date, now);

      final reversedJson = model.toJson();
      expect(reversedJson['amount'], 2500.0);
      expect(reversedJson['date'], timestamp);
      expect(reversedJson['appointmentId'], 'app1');
    });

    test('should omit appointmentId in JSON if null', () {
      final model = PaymentModel(
        id: 'pay2',
        patientId: 'pat1',
        providerId: 'prov1',
        appointmentId: null,
        amount: 100.0,
        date: now,
      );

      final json = model.toJson();
      expect(json.containsKey('appointmentId'), false);
    });
  });
}
