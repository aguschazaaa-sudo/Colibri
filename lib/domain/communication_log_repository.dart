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

  /// Calls the `triggerManualReminders` Cloud Function to bulk-queue
  /// WhatsApp reminders for every patient of the authenticated provider
  /// that has outstanding debt. Returns the count of queued reminders.
  Future<Either<Failure, int>> triggerBulkReminders();
}
