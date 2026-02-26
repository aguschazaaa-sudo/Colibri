import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cobrador/data/models/appointment_model.dart';
import 'package:cobrador/data/models/payment_model.dart';
import 'package:cobrador/data/models/recurring_appointment_model.dart';
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/ledger_repository.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:fpdart/fpdart.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  LedgerRepositoryImpl(this._firestore, this._functions);

  /// Returns a reference to `providers/{providerId}/patients/{patientId}`.
  DocumentReference<Map<String, dynamic>> _patientRef(
    String providerId,
    String patientId,
  ) {
    return _firestore
        .collection('providers')
        .doc(providerId)
        .collection('patients')
        .doc(patientId);
  }

  @override
  Stream<List<Appointment>> watchAppointments({
    required String providerId,
    required String patientId,
  }) {
    if (patientId.isEmpty) {
      return _firestore
          .collectionGroup('appointments')
          .where('providerId', isEqualTo: providerId)
          .snapshots()
          .handleError((error) {
            print('🔥 Error in collectionGroup appointments: $error');
          })
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final model = AppointmentModel.fromJson(doc.data(), doc.id);
              return model.toEntity();
            }).toList();
          });
    }

    return _patientRef(providerId, patientId)
        .collection('appointments')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .handleError((error) {
          print('🔥 Error in collection appointments: $error');
        })
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
    if (patientId.isEmpty) {
      return _firestore
          .collectionGroup('payments')
          .where('providerId', isEqualTo: providerId)
          .snapshots()
          .handleError((error) {
            print('🔥 Error in collectionGroup payments: $error');
          })
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final model = PaymentModel.fromJson(doc.data(), doc.id);
              return model.toEntity();
            }).toList();
          });
    }

    return _patientRef(providerId, patientId)
        .collection('payments')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .handleError((error) {
          print('🔥 Error in collection payments: $error');
        })
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
    if (patientId.isEmpty) {
      return _firestore
          .collectionGroup('recurring_appointments')
          .where('providerId', isEqualTo: providerId)
          .snapshots()
          .handleError((error) {
            print('🔥 Error in collectionGroup recurring_appointments: $error');
          })
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final model = RecurringAppointmentModel.fromJson(
                doc.data(),
                doc.id,
              );
              return model.toEntity();
            }).toList();
          });
    }

    return _patientRef(providerId, patientId)
        .collection('recurring_appointments')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .handleError((error) {
          print('🔥 Error in collection recurring_appointments: $error');
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final model = RecurringAppointmentModel.fromJson(
              doc.data(),
              doc.id,
            );
            return model.toEntity();
          }).toList();
        });
  }

  @override
  Future<Either<Failure, Appointment>> createAppointment(
    Appointment appointment,
  ) async {
    try {
      final docRef =
          _patientRef(
            appointment.providerId,
            appointment.patientId,
          ).collection('appointments').doc();
      final entityWithId = appointment.copyWith(id: docRef.id);
      final model = AppointmentModel.fromEntity(entityWithId);

      await docRef.set(model.toJson());

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
  ) async {
    try {
      final docRef =
          _patientRef(
            recurringAppointment.providerId,
            recurringAppointment.patientId,
          ).collection('recurring_appointments').doc();
      final entityWithId = recurringAppointment.copyWith(id: docRef.id);
      final model = RecurringAppointmentModel.fromEntity(entityWithId);

      await docRef.set(model.toJson());

      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Left(
          Failure.serverError(
            'No tienes permisos para crear turnos recurrentes.',
          ),
        );
      }
      return Left(Failure.serverError(e.message ?? 'Unknown Firebase Error'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecurringAppointment(
    String providerId,
    String patientId,
    String recurringAppointmentId,
  ) async {
    try {
      await _patientRef(providerId, patientId)
          .collection('recurring_appointments')
          .doc(recurringAppointmentId)
          .delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(
        Failure.serverError(
          e.message ?? 'Error deleting recurring appointment',
        ),
      );
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> registerPayment(Payment payment) async {
    try {
      final callable = _functions.httpsCallable('payments-registerPayment');

      final result = await callable.call(<String, dynamic>{
        'patientId': payment.patientId,
        'amount': payment.amount,
        if (payment.appointmentId != null)
          'appointmentId': payment.appointmentId,
      });

      final paymentId = result.data['paymentId'] as String;

      final entityWithId = payment.copyWith(
        id: paymentId,
        date: DateTime.now(),
      );

      return Right(entityWithId);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        Failure.serverError(e.message ?? 'Cloud Function Error: ${e.code}'),
      );
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }
}
