import 'package:fpdart/fpdart.dart';
import 'failure.dart';
import 'communication_log.dart';

abstract class CommunicationLogRepository {
  /// Enqueues a WhatsApp reminder for a specific patient.
  /// The backend Cloud Function will process this log.
  Future<Either<Failure, CommunicationLog>> enqueueWhatsAppReminder({
    required String providerId,
    required String patientId,
    required double totalDebtAtThatTime,
  });
}
