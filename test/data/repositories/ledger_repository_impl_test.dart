import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/data/repositories/ledger_repository_impl.dart';
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LedgerRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = LedgerRepositoryImpl(fakeFirestore);
  });

  // ─── createAppointment ─────────────────────────────────────

  group('createAppointment', () {
    final tAppointment = Appointment(
      id: '',
      patientId: 'pat1',
      providerId: 'prov1',
      date: DateTime(2026, 1, 15),
      concept: 'Odontologia',
      totalAmount: 50.0,
      amountPaid: 0.0,
      status: AppointmentStatus.unpaid,
    );

    test(
      'should return created entity with auto-generated ID when successful',
      () async {
        final result = await repository.createAppointment(tAppointment);

        expect(result.isRight(), true);
        result.map((appointment) {
          expect(appointment.id, isNotEmpty);
          expect(appointment.concept, 'Odontologia');
          expect(appointment.totalAmount, 50.0);
          expect(appointment.patientId, 'pat1');
          expect(appointment.providerId, 'prov1');
        });

        final snapshot = await fakeFirestore.collection('appointments').get();
        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first.data()['concept'], 'Odontologia');
      },
    );

    test('should persist the correct fields in Firestore document', () async {
      await repository.createAppointment(tAppointment);

      final snapshot = await fakeFirestore.collection('appointments').get();
      final data = snapshot.docs.first.data();

      expect(data['patientId'], 'pat1');
      expect(data['providerId'], 'prov1');
      expect(data['concept'], 'Odontologia');
      expect(data['totalAmount'], 50.0);
      expect(data['amountPaid'], 0.0);
      expect(data['status'], 'unpaid');
    });
  });

  // ─── registerPayment ───────────────────────────────────────

  group('registerPayment', () {
    final tPayment = Payment(
      id: '',
      patientId: 'pat1',
      providerId: 'prov1',
      amount: 150.0,
      date: DateTime(2026, 2, 10),
    );

    test('should return Payment with auto-generated ID', () async {
      final result = await repository.registerPayment(tPayment);

      expect(result.isRight(), true);
      result.map((payment) {
        expect(payment.id, isNotEmpty);
        expect(payment.amount, 150.0);
        expect(payment.patientId, 'pat1');
      });
    });

    test('should persist payment data in Firestore', () async {
      await repository.registerPayment(tPayment);

      final snapshot = await fakeFirestore.collection('payments').get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['patientId'], 'pat1');
      expect(data['providerId'], 'prov1');
      expect(data['amount'], 150.0);
    });

    test('should store optional appointmentId when provided', () async {
      final paymentWithAppt = tPayment.copyWith(appointmentId: 'appt_123');
      await repository.registerPayment(paymentWithAppt);

      final snapshot = await fakeFirestore.collection('payments').get();
      expect(snapshot.docs.first.data()['appointmentId'], 'appt_123');
    });
  });

  // ─── watchAppointments ─────────────────────────────────────

  group('watchAppointments', () {
    test('should emit empty list when no appointments exist', () async {
      final stream = repository.watchAppointments(
        providerId: 'prov1',
        patientId: 'pat1',
      );

      await expectLater(stream, emits(isEmpty));
    });

    test(
      'should only return appointments for the given patient and provider',
      () async {
        await fakeFirestore.collection('appointments').add({
          'patientId': 'pat1',
          'providerId': 'prov1',
          'concept': 'Consulta A',
          'totalAmount': 100.0,
          'amountPaid': 0.0,
          'status': 'unpaid',
          'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });
        await fakeFirestore.collection('appointments').add({
          'patientId': 'pat_other',
          'providerId': 'prov1',
          'concept': 'Consulta B',
          'totalAmount': 200.0,
          'amountPaid': 0.0,
          'status': 'unpaid',
          'date': Timestamp.fromDate(DateTime(2026, 1, 2)),
        });

        final stream = repository.watchAppointments(
          providerId: 'prov1',
          patientId: 'pat1',
        );
        final appointments = await stream.first;

        expect(appointments.length, 1);
        expect(appointments.first.concept, 'Consulta A');
      },
    );
  });

  // ─── watchPayments ─────────────────────────────────────────

  group('watchPayments', () {
    test('should emit empty list when no payments exist', () async {
      final stream = repository.watchPayments(
        providerId: 'prov1',
        patientId: 'pat1',
      );

      await expectLater(stream, emits(isEmpty));
    });

    test(
      'should only return payments for the given patient and provider',
      () async {
        await fakeFirestore.collection('payments').add({
          'patientId': 'pat1',
          'providerId': 'prov1',
          'amount': 50.0,
          'date': Timestamp.fromDate(DateTime(2026, 1, 5)),
        });
        await fakeFirestore.collection('payments').add({
          'patientId': 'pat_other',
          'providerId': 'prov1',
          'amount': 75.0,
          'date': Timestamp.fromDate(DateTime(2026, 1, 6)),
        });

        final stream = repository.watchPayments(
          providerId: 'prov1',
          patientId: 'pat1',
        );
        final payments = await stream.first;

        expect(payments.length, 1);
        expect(payments.first.amount, 50.0);
      },
    );
  });

  // ─── NEGATIVE PATHS: Malformed Data ────────────────────────

  group('watchAppointments - malformed data', () {
    test('should error on documents with missing required fields', () async {
      await fakeFirestore.collection('appointments').add({
        'patientId': 'pat1',
        'providerId': 'prov1',
        // Missing: concept, totalAmount, amountPaid, status, date
      });

      final stream = repository.watchAppointments(
        providerId: 'prov1',
        patientId: 'pat1',
      );

      await expectLater(stream, emitsError(isA<TypeError>()));
    });
  });

  group('watchPayments - malformed data', () {
    test('should error on documents with missing required fields', () async {
      await fakeFirestore.collection('payments').add({
        'patientId': 'pat1',
        'providerId': 'prov1',
        // Missing: amount, date
      });

      final stream = repository.watchPayments(
        providerId: 'prov1',
        patientId: 'pat1',
      );

      await expectLater(stream, emitsError(isA<TypeError>()));
    });
  });
}
