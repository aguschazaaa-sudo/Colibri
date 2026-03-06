import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/data/models/dashboard_report_model.dart';
import 'package:cobrador/data/models/provider_model.dart';
import 'package:cobrador/domain/dashboard_report.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/provider_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  final FirebaseFirestore _firestore;

  ProviderRepositoryImpl(this._firestore);

  @override
  Stream<Provider?> watchProvider(String providerId) {
    return _firestore.collection('providers').doc(providerId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final model = ProviderModel.fromJson(snapshot.data()!);
      // Force set ID since we extract it from document
      return model.toEntity().copyWith(id: snapshot.id);
    });
  }

  @override
  Future<Either<Failure, Provider>> updateProviderProfile(
    Provider provider,
  ) async {
    try {
      final model = ProviderModel(
        id: provider.id,
        email: provider.email,
        name: provider.name,
        subscriptionStatus: provider.subscriptionStatus,
        plan: provider.plan,
        subscriptionExpiresAt: provider.subscriptionExpiresAt,
        defaultMonthlyInterestRate: provider.defaultMonthlyInterestRate,
        createdAt: provider.createdAt,
      );

      // Using merge to avoid overwriting backend-controlled fields like subscription
      // accidentally if the model was out of sync.
      await _firestore
          .collection('providers')
          .doc(provider.id)
          .set(model.toJson(), SetOptions(merge: true));

      return Right(provider);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message ?? 'Firebase update failed.'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }

  @override
  Stream<DashboardReport> watchDashboardReport(String providerId) async* {
    if (providerId.isEmpty) {
      yield DashboardReport.empty();
      return;
    }

    try {
      await for (final snapshot
          in _firestore
              .collection('providers')
              .doc(providerId)
              .collection('metrics')
              .doc('dashboard')
              .snapshots()) {
        if (!snapshot.exists) {
          yield DashboardReport.empty();
        } else {
          yield DashboardReportModel.fromFirestore(snapshot).toDomain();
        }
      }
    } catch (_) {
      // Fallback in case of permission errors or network issues
      // to avoid infinite loading skeletons.
      yield DashboardReport.empty();
    }
  }

  @override
  Future<Either<Failure, Unit>> addNonWorkingDay(
    String providerId,
    String day,
  ) async {
    try {
      await _firestore.collection('providers').doc(providerId).update({
        'nonWorkingDays': FieldValue.arrayUnion([day]),
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message ?? 'Failed to add day.'));
    } catch (_) {
      return const Left(Failure.serverError('Failed to add day.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeNonWorkingDay(
    String providerId,
    String day,
  ) async {
    try {
      await _firestore.collection('providers').doc(providerId).update({
        'nonWorkingDays': FieldValue.arrayRemove([day]),
      });
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message ?? 'Failed to remove day.'));
    } catch (_) {
      return const Left(Failure.serverError('Failed to remove day.'));
    }
  }
}
