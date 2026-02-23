import 'package:cobrador/data/repositories/communication_log_repository_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CommunicationLogRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = CommunicationLogRepositoryImpl(fakeFirestore);
  });

  group('enqueueWhatsAppReminder', () {
    test(
      'should create a communication log in Firestore and return it',
      () async {
        final result = await repository.enqueueWhatsAppReminder(
          providerId: 'prov1',
          patientId: 'pat1',
          totalDebtAtThatTime: 500.0,
        );

        expect(result.isRight(), true);
        result.map((log) {
          expect(log.id, isNotEmpty);
          expect(log.providerId, 'prov1');
          expect(log.patientId, 'pat1');
          expect(log.status, 'pending');
          expect(log.totalDebtAtThatTime, 500.0);
        });

        // Verify data in Firestore
        final snapshot = await fakeFirestore.collection('communications').get();
        expect(snapshot.docs.length, 1);

        final data = snapshot.docs.first.data();
        expect(data['providerId'], 'prov1');
        expect(data['patientId'], 'pat1');
        expect(data['type'], 'whatsapp_reminder');
        expect(data['status'], 'pending');
        expect(data['totalDebtAtThatTime'], 500.0);
      },
    );

    test('should generate unique IDs for each log', () async {
      final result1 = await repository.enqueueWhatsAppReminder(
        providerId: 'prov1',
        patientId: 'pat1',
        totalDebtAtThatTime: 100.0,
      );
      final result2 = await repository.enqueueWhatsAppReminder(
        providerId: 'prov1',
        patientId: 'pat1',
        totalDebtAtThatTime: 200.0,
      );

      final id1 = result1.getOrElse((_) => throw 'fail').id;
      final id2 = result2.getOrElse((_) => throw 'fail').id;

      expect(id1, isNot(id2));
    });
  });
}
