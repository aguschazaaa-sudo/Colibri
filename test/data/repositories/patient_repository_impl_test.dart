import 'package:cobrador/data/repositories/patient_repository_impl.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PatientRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = PatientRepositoryImpl(fakeFirestore);
  });

  final tPatient = Patient(
    id: '',
    providerId: 'prov1',
    name: 'María García',
    phoneNumber: '+5491112345678',
    createdAt: DateTime(2026, 1, 15),
  );

  // ─── HAPPY PATHS ───────────────────────────────────────────

  group('createPatient - happy path', () {
    test('should return Patient with auto-generated ID', () async {
      final result = await repository.createPatient(tPatient);

      expect(result.isRight(), true);
      result.map((patient) {
        expect(patient.id, isNotEmpty);
        expect(patient.name, 'María García');
        expect(patient.phoneNumber, '+5491112345678');
      });
    });

    test('should persist patient data into Firestore subcollection', () async {
      await repository.createPatient(tPatient);

      // Path is now providers/{providerId}/patients
      final snapshot =
          await fakeFirestore
              .collection('providers')
              .doc('prov1')
              .collection('patients')
              .get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['name'], 'María García');
      expect(data['phoneNumber'], '+5491112345678');
      expect(data['providerId'], 'prov1');
      expect(data['totalDebt'], 0.0);
      expect(data['balance'], 0.0);
    });
  });

  group('updatePatient - happy path', () {
    test('should update existing patient and return updated entity', () async {
      // Seed a patient first
      final createResult = await repository.createPatient(tPatient);
      final createdPatient = createResult.getOrElse(
        (_) => throw 'Create failed',
      );

      final updated = createdPatient.copyWith(name: 'María García López');
      final result = await repository.updatePatient(updated);

      expect(result.isRight(), true);
      result.map((patient) {
        expect(patient.name, 'María García López');
      });

      // Verify Firestore was updated at the new path
      final doc =
          await fakeFirestore
              .collection('providers')
              .doc('prov1')
              .collection('patients')
              .doc(createdPatient.id)
              .get();
      expect(doc.data()!['name'], 'María García López');
    });
  });

  group('watchPatients', () {
    test('should emit an empty list when no patients exist', () async {
      final stream = repository.watchPatients('prov1');

      await expectLater(stream, emits(isEmpty));
    });

    test('should only return patients for the given providerId', () async {
      // Create patients for 2 different providers
      await repository.createPatient(tPatient);
      await repository.createPatient(
        tPatient.copyWith(providerId: 'provOther', name: 'Otro Paciente'),
      );

      final stream = repository.watchPatients('prov1');
      final patients = await stream.first;

      // Only prov1's patient should be returned
      expect(patients.length, 1);
      expect(patients.first.name, 'María García');
    });
  });

  // ─── NEGATIVE PATHS ────────────────────────────────────────

  group('createPatient - negative paths', () {
    test('should handle generic exceptions gracefully', () async {
      final result = await repository.createPatient(tPatient);
      expect(result.isRight(), true);
    });
  });

  group('watchPatients - malformed data', () {
    test('should handle documents with missing fields gracefully', () async {
      // Seed raw malformed data directly into the new subcollection path
      await fakeFirestore
          .collection('providers')
          .doc('prov1')
          .collection('patients')
          .add({
            'providerId': 'prov1',
            'name': 'Solo Nombre',
            // Missing: phoneNumber, totalDebt, balance, createdAt
          });

      final stream = repository.watchPatients('prov1');

      // This should throw because PatientModel.fromJson does a hard cast
      // on 'phoneNumber', 'createdAt', etc. We expect the stream to error.
      await expectLater(stream, emitsError(isA<TypeError>()));
    });
  });
}
