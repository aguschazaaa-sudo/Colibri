import 'package:fpdart/fpdart.dart';
import 'failure.dart';
import 'appointment.dart';
import 'payment.dart';
import 'recurring_appointment.dart';

abstract class LedgerRepository {
  // Observa los turnos de un paciente
  Stream<List<Appointment>> watchAppointments({
    required String providerId,
    required String patientId,
  });

  // Obtiene una página de pagos con su cursor
  Future<Either<Failure, ({List<Payment> items, dynamic cursor})>>
  getPaymentsPage({
    required String providerId,
    String? patientId,
    dynamic cursor,
    int limit = 8,
  });

  // Observa los turnos recurrentes de un paciente
  Stream<List<RecurringAppointment>> watchRecurringAppointments({
    required String providerId,
    required String patientId,
  });

  // Crea un turno (genera deuda)
  Future<Either<Failure, Appointment>> createAppointment(
    Appointment appointment,
  );

  // Actualiza un turno existente
  Future<Either<Failure, void>> updateAppointment(
    Appointment appointment,
  );

  // Crea un turno recurrente
  Future<Either<Failure, RecurringAppointment>> createRecurringAppointment(
    RecurringAppointment recurringAppointment,
  );

  // Actualiza un turno recurrente
  Future<Either<Failure, void>> updateRecurringAppointment(
    RecurringAppointment recurringAppointment, {
    bool resetSchedule = false,
  });

  // Elimina un turno
  Future<Either<Failure, void>> deleteAppointment(
    String providerId,
    String patientId,
    String appointmentId,
  );

  // Detiene o elimina un turno recurrente
  Future<Either<Failure, void>> deleteRecurringAppointment(
    String providerId,
    String patientId,
    String recurringAppointmentId,
  );

  // Registra un pago y aplica la lógica de reducción de deuda (FIFO)
  Future<Either<Failure, Payment>> registerPayment(Payment payment);

  // Elimina un pago
  Future<Either<Failure, void>> deletePayment(
    String providerId,
    String patientId,
    String paymentId,
  );

  /// Obtiene todos los turnos de un profesional en un día dado (todos sus pacientes).
  /// Excluye turnos cancelados. Usado para detección de solapamientos.
  Future<List<Appointment>> getAppointmentsForDay({
    required String providerId,
    required DateTime day,
  });

  /// Cancela una ocurrencia individual de un turno recurrente.
  ///
  /// Agrega [dateKey] (formato "yyyy-MM-dd") al array [cancelledDates] del
  /// documento recurrente. Si [existingAppointmentId] no es null, elimina
  /// también el turno ya generado en el mismo batch.
  Future<Either<Failure, void>> cancelOccurrence({
    required String providerId,
    required String patientId,
    required String recurringAppointmentId,
    required String dateKey,
    String? existingAppointmentId,
  });
}
