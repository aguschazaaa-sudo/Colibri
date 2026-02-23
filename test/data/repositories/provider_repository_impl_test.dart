import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/data/repositories/provider_repository_impl.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderRepositoryImpl repository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = ProviderRepositoryImpl(fakeFirestore);
  });

  final tProvider = Provider(
    id: 'prov1',
    email: 'doc@example.com',
    name: 'Dr. House',
    subscriptionStatus: SubscriptionStatus.active,
    defaultMonthlyInterestRate: 0.05,
    createdAt: DateTime(2025, 6, 1),
  );

  // ─── HAPPY PATHS ───────────────────────────────────────────

  group('updateProviderProfile - happy path', () {
    test('should write provider data to Firestore and return entity', () async {
      final result = await repository.updateProviderProfile(tProvider);

      expect(result.isRight(), true);
      result.map((provider) {
        expect(provider.name, 'Dr. House');
        expect(provider.email, 'doc@example.com');
      });

      // Verify Firestore doc was written
      final doc =
          await fakeFirestore.collection('providers').doc('prov1').get();
      expect(doc.exists, true);
      expect(doc.data()!['name'], 'Dr. House');
      expect(doc.data()!['defaultMonthlyInterestRate'], 0.05);
    });

    test(
      'should use merge strategy so unrelated fields are preserved',
      () async {
        // Pre-seed a field that the model doesn't control
        await fakeFirestore.collection('providers').doc('prov1').set({
          'stripeCustomerId': 'cus_abc123',
        });

        await repository.updateProviderProfile(tProvider);

        final doc =
            await fakeFirestore.collection('providers').doc('prov1').get();
        // The merge should preserve the stripe field
        expect(doc.data()!['stripeCustomerId'], 'cus_abc123');
        expect(doc.data()!['name'], 'Dr. House');
      },
    );
  });

  group('watchProvider', () {
    test('should emit null when provider document does not exist', () async {
      final stream = repository.watchProvider('nonexistent_id');

      await expectLater(stream, emits(isNull));
    });

    test('should emit Provider entity when document exists', () async {
      // Seed provider data
      await fakeFirestore.collection('providers').doc('prov1').set({
        'id': 'prov1',
        'email': 'doc@example.com',
        'name': 'Dr. House',
        'subscriptionStatus': 'active',
        'defaultMonthlyInterestRate': 0.05,
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 1)),
      });

      final stream = repository.watchProvider('prov1');
      final provider = await stream.first;

      expect(provider, isNotNull);
      expect(provider!.name, 'Dr. House');
      expect(provider.subscriptionStatus, SubscriptionStatus.active);
    });
  });

  // ─── NEGATIVE PATHS ────────────────────────────────────────

  group('watchProvider - malformed data', () {
    test('should handle document with missing required fields', () async {
      // Seed malformed data (missing 'email', 'name', 'createdAt')
      await fakeFirestore.collection('providers').doc('bad_prov').set({
        'id': 'bad_prov',
        'subscriptionStatus': 'active',
        // Missing: email, name, createdAt, defaultMonthlyInterestRate
      });

      final stream = repository.watchProvider('bad_prov');

      // ProviderModel.fromJson does hard casts, this should error
      await expectLater(stream, emitsError(isA<TypeError>()));
    });

    test(
      'should fallback to default subscriptionStatus when value is invalid',
      () async {
        await fakeFirestore.collection('providers').doc('prov_bad_status').set({
          'id': 'prov_bad_status',
          'email': 'test@test.com',
          'name': 'Test',
          'subscriptionStatus': 'nonexistent_status', // Invalid enum value
          'defaultMonthlyInterestRate': 0.0,
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });

        final stream = repository.watchProvider('prov_bad_status');
        final provider = await stream.first;

        // Should fallback to 'active' via orElse in fromJson
        expect(provider, isNotNull);
        expect(provider!.subscriptionStatus, SubscriptionStatus.active);
      },
    );
  });
}
