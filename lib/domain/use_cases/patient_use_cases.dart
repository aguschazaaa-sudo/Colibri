import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/patient_repository.dart';

class CreatePatientUseCase {
  final PatientRepository _repository;

  CreatePatientUseCase(this._repository);

  Future<Either<Failure, Patient>> execute(Patient patient) async {
    if (patient.name.trim().isEmpty) {
      return const Left(
        Failure.validationError('El nombre del paciente no puede estar vacío.'),
      );
    }

    if (patient.phoneNumber.trim().length < 8) {
      return const Left(
        Failure.validationError(
          'El teléfono debe tener un formato válido (mínimo 8 caracteres).',
        ),
      );
    }

    return _repository.createPatient(patient);
  }
}

class UpdatePatientUseCase {
  final PatientRepository _repository;

  UpdatePatientUseCase(this._repository);

  Future<Either<Failure, Patient>> execute(Patient patient) async {
    if (patient.name.trim().isEmpty) {
      return const Left(
        Failure.validationError('El nombre del paciente no puede estar vacío.'),
      );
    }

    if (patient.phoneNumber.trim().length < 8) {
      return const Left(
        Failure.validationError(
          'El teléfono debe tener un formato válido (mínimo 8 caracteres).',
        ),
      );
    }

    return _repository.updatePatient(patient);
  }
}
