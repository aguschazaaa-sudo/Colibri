import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/data/models/appointment_model.dart';
import 'package:cobrador/data/models/payment_model.dart';
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/ledger_repository.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:fpdart/fpdart.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final FirebaseFirestore _firestore;

  LedgerRepositoryImpl(this._firestore);

  @override
  Stream<List<Appointment>> watchAppointments({
    required String providerId,
    required String patientId,
  }) {
    return _firestore
        .collection('appointments')
        .where('providerId', isEqualTo: providerId)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final model = AppointmentModel.fromJson(doc.data(), doc.id);
            return model.toEntity();
          }).toList();
        });
  }

  @override
  Stream<List<Payment>> watchPayments({
    required String providerId,
    required String patientId,
  }) {
    return _firestore
        .collection('payments')
        .where('providerId', isEqualTo: providerId)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final model = PaymentModel.fromJson(doc.data(), doc.id);
            return model.toEntity();
          }).toList();
        });
  }

  @override
  Stream<List<RecurringAppointment>> watchRecurringAppointments({
    required String providerId,
    required String patientId,
  }) {
    // TODO: Implement recurring appointments in Nivel 2.5
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Appointment>> createAppointment(
    Appointment appointment,
  ) async {
    try {
      final docRef = _firestore.collection('appointments').doc();
      final entityWithId = appointment.copyWith(id: docRef.id);
      final model = AppointmentModel.fromEntity(entityWithId);

      await docRef.set(model.toJson());

      // Mapearlo de vuelta puede ser redundante pero respeta
      // el flow puro de devolver la entidad con el ID asignado real.
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Left(
          Failure.serverError('No tienes permisos para crear turnos.'),
        );
      }
      return Left(Failure.serverError(e.message ?? 'Unknown Firebase Error'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RecurringAppointment>> createRecurringAppointment(
    RecurringAppointment recurringAppointment,
  ) {
    // TODO: Implement recurring
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> deleteRecurringAppointment(
    String providerId,
    String patientId,
    String recurringAppointmentId,
  ) {
    // TODO: implement deleteRecurringAppointment
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Payment>> registerPayment(Payment payment) async {
    // CQRS Architecture: Payments should ideally be registered via a Cloud Function
    // called via `httpsCallable`. To fulfill the Data Layer initially,
    // we'll implement the direct method but log a soft warning for migration.
    try {
      final docRef = _firestore.collection('payments').doc();
      final entityWithId = payment.copyWith(id: docRef.id);
      final model = PaymentModel.fromEntity(entityWithId);

      // Warning: Direct write bypassed the Cloud Function strict transaction
      await docRef.set(model.toJson());

      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message ?? 'Firebase Error'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }
}
