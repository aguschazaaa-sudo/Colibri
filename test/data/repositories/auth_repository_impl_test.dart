import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/data/repositories/auth_repository_impl.dart';
import 'package:cobrador/data/datasources/firebase_auth_data_source.dart';
import 'package:cobrador/data/models/provider_model.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuthDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockFirebaseAuthDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  final tProviderModel = ProviderModel(
    id: 'test_id',
    email: 'test@example.com',
    name: 'Test Name',
    subscriptionStatus: SubscriptionStatus.active,
    defaultMonthlyInterestRate: 0.10,
    createdAt: DateTime(2023, 1, 1),
  );

  final tProviderEntity = tProviderModel.toEntity();

  group('signInWithEmailAndPassword', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';

    test('should return Provider when data source succeeds', () async {
      // arrange
      when(
        () => mockDataSource.signInWithEmailAndPassword(tEmail, tPassword),
      ).thenAnswer((_) async => Right(tProviderModel));

      // act
      final result = await repository.signInWithEmailAndPassword(
        tEmail,
        tPassword,
      );

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not be left'), (r) {
        expect(r.id, tProviderEntity.id);
        expect(r.email, tProviderEntity.email);
      });
    });

    test('should return Failure when data source fails', () async {
      // arrange
      const tFailure = Failure.invalidCredentials();
      when(
        () => mockDataSource.signInWithEmailAndPassword(tEmail, tPassword),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await repository.signInWithEmailAndPassword(
        tEmail,
        tPassword,
      );

      // assert
      expect(result, const Left(tFailure));
    });
  });

  group('registerWithEmailAndPassword', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tName = 'Test Name';

    test('should return Provider when data source succeeds', () async {
      // arrange
      when(
        () => mockDataSource.registerWithEmailAndPassword(
          tEmail,
          tPassword,
          tName,
        ),
      ).thenAnswer((_) async => Right(tProviderModel));

      // act
      final result = await repository.registerWithEmailAndPassword(
        tEmail,
        tPassword,
        tName,
      );

      // assert
      expect(result.isRight(), true);
    });
  });

  group('signInWithGoogle', () {
    test('should return Provider when data source succeeds', () async {
      // arrange
      when(
        () => mockDataSource.signInWithGoogle(),
      ).thenAnswer((_) async => Right(tProviderModel));

      // act
      final result = await repository.signInWithGoogle();

      // assert
      expect(result.isRight(), true);
    });
  });

  group('sendPasswordResetEmail', () {
    const tEmail = 'test@example.com';

    test('should return Unit when data source succeeds', () async {
      // arrange
      when(
        () => mockDataSource.sendPasswordResetEmail(tEmail),
      ).thenAnswer((_) async => const Right(unit));

      // act
      final result = await repository.sendPasswordResetEmail(tEmail);

      // assert
      expect(result, const Right(unit));
    });
  });
}
