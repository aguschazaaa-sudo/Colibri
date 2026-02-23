import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/data/models/patient_model.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/patient_repository.dart';
import 'package:fpdart/fpdart.dart';

class PatientRepositoryImpl implements PatientRepository {
  final FirebaseFirestore _firestore;

  PatientRepositoryImpl(this._firestore);

  @override
  Stream<List<Patient>> watchPatients(String providerId) {
    return _firestore
        .collection('patients')
        .where('providerId', isEqualTo: providerId)
        // Opcional: .orderBy('name') si se quiere un orden por defecto desde la BD
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final model = PatientModel.fromJson(doc.data(), doc.id);
            return model.toEntity();
          }).toList();
        });
  }

  @override
  Future<Either<Failure, Patient>> createPatient(Patient patient) async {
    try {
      final docRef = _firestore.collection('patients').doc();
      final entityWithId = patient.copyWith(id: docRef.id);
      final model = PatientModel.fromEntity(entityWithId);

      await docRef.set(model.toJson());

      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const Left(
          Failure.serverError('No tienes permisos para crear pacientes.'),
        );
      }
      return Left(Failure.serverError(e.message ?? 'Unknown Firebase Error'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Patient>> updatePatient(Patient patient) async {
    try {
      final model = PatientModel.fromEntity(patient);
      await _firestore
          .collection('patients')
          .doc(patient.id)
          .update(model.toJson());

      return Right(patient);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        return const Left(Failure.serverError('Paciente no encontrado.'));
      }
      return Left(Failure.serverError(e.message ?? 'Firebase Error'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }
}
