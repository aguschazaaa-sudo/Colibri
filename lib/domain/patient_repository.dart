import 'package:fpdart/fpdart.dart';
import 'failure.dart';
import 'patient.dart';

abstract class PatientRepository {
  Stream<List<Patient>> watchPatients(String providerId);
  Future<Either<Failure, Patient>> createPatient(Patient patient);
  Future<Either<Failure, Patient>> updatePatient(Patient patient);
}
