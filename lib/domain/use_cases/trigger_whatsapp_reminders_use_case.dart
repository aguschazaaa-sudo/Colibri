import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/domain/communication_log_repository.dart';

class TriggerWhatsAppRemindersUseCase {
  final CommunicationLogRepository _repository;

  TriggerWhatsAppRemindersUseCase(this._repository);

  /// Triggers a WhatsApp reminder for a specific patient if they have deuda.
  Future<Either<Failure, CommunicationLog>> execute(Patient patient) async {
    if (patient.totalDebt <= 0) {
      return const Left(
        Failure.validationError('El paciente no tiene deuda pendiente.'),
      );
    }

    return _repository.enqueueWhatsAppReminder(
      providerId: patient.providerId,
      patientId: patient.id,
      totalDebtAtThatTime: patient.totalDebt,
    );
  }
}
