import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/ledger_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Cancels a single occurrence of a recurring appointment rule.
///
/// Adds [dateKey] to [RecurringAppointment.cancelledDates] via an atomic
/// Firestore batch. If [existingAppointmentId] is provided, also deletes the
/// already-generated appointment in the same batch.
class CancelRecurringOccurrenceUseCase {
  final LedgerRepository _repository;

  const CancelRecurringOccurrenceUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String providerId,
    required String patientId,
    required String recurringAppointmentId,
    required String dateKey,
    String? existingAppointmentId,
  }) =>
      _repository.cancelOccurrence(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringAppointmentId,
        dateKey: dateKey,
        existingAppointmentId: existingAppointmentId,
      );
}
