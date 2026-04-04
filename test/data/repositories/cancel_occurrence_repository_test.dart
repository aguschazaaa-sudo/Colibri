import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cobrador/data/repositories/ledger_repository_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late LedgerRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;

  const providerId = 'prov1';
  const patientId = 'pat1';
  const recurringId = 'rec1';
  const dateKey = '2026-04-10';

  CollectionReference<Map<String, dynamic>> recurringRef() =>
      fakeFirestore
          .collection('providers')
          .doc(providerId)
          .collection('patients')
          .doc(patientId)
          .collection('recurring_appointments');

  CollectionReference<Map<String, dynamic>> appointmentsRef() =>
      fakeFirestore
          .collection('providers')
          .doc(providerId)
          .collection('patients')
          .doc(patientId)
          .collection('appointments');

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    repository = LedgerRepositoryImpl(fakeFirestore, mockFunctions);
  });

  group('cancelOccurrence', () {
    test('adds dateKey to cancelledDates on recurring doc', () async {
      await recurringRef().doc(recurringId).set({
        'patientId': patientId,
        'providerId': providerId,
        'cancelledDates': [],
      });

      final result = await repository.cancelOccurrence(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
      );

      expect(result.isRight(), isTrue);

      final doc = await recurringRef().doc(recurringId).get();
      final cancelledDates = List<String>.from(
        doc.data()!['cancelledDates'] as List,
      );
      expect(cancelledDates, contains(dateKey));
    });

    test('deletes appointment doc when existingAppointmentId is provided', () async {
      const appointmentId = 'apt1';

      await recurringRef().doc(recurringId).set({
        'patientId': patientId,
        'providerId': providerId,
        'cancelledDates': [],
      });

      await appointmentsRef().doc(appointmentId).set({
        'patientId': patientId,
        'providerId': providerId,
        'recurringAppointmentId': recurringId,
        'dateKey': dateKey,
        'concept': 'Consulta',
        'totalAmount': 5000.0,
        'amountPaid': 0.0,
        'status': 'unpaid',
        'date': Timestamp.fromDate(DateTime(2026, 4, 10)),
      });

      final result = await repository.cancelOccurrence(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
        existingAppointmentId: appointmentId,
      );

      expect(result.isRight(), isTrue);

      final aptDoc = await appointmentsRef().doc(appointmentId).get();
      expect(aptDoc.exists, isFalse);

      final recDoc = await recurringRef().doc(recurringId).get();
      final cancelledDates = List<String>.from(
        recDoc.data()!['cancelledDates'] as List,
      );
      expect(cancelledDates, contains(dateKey));
    });

    test('handles missing appointment gracefully (no existingAppointmentId)', () async {
      await recurringRef().doc(recurringId).set({
        'patientId': patientId,
        'providerId': providerId,
        'cancelledDates': [],
      });

      // No appointment doc seeded — should still succeed
      final result = await repository.cancelOccurrence(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
        existingAppointmentId: null,
      );

      expect(result.isRight(), isTrue);
    });

    test('arrayUnion is idempotent — adding same dateKey twice stays in list once', () async {
      await recurringRef().doc(recurringId).set({
        'patientId': patientId,
        'providerId': providerId,
        'cancelledDates': [dateKey],
      });

      final result = await repository.cancelOccurrence(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringId,
        dateKey: dateKey,
      );

      expect(result.isRight(), isTrue);

      final doc = await recurringRef().doc(recurringId).get();
      final cancelledDates = List<String>.from(
        doc.data()!['cancelledDates'] as List,
      );
      // arrayUnion ensures no duplicates
      expect(cancelledDates.where((d) => d == dateKey).length, 1);
    });
  });
}
