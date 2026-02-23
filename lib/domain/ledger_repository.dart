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

  // Observa los pagos de un paciente
  Stream<List<Payment>> watchPayments({
    required String providerId,
    required String patientId,
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

  // Crea un turno recurrente
  Future<Either<Failure, RecurringAppointment>> createRecurringAppointment(
    RecurringAppointment recurringAppointment,
  );

  // Detiene o elimina un turno recurrente
  Future<Either<Failure, void>> deleteRecurringAppointment(
    String providerId,
    String patientId,
    String recurringAppointmentId,
  );

  // Registra un pago y aplica la lógica de reducción de deuda (FIFO)
  Future<Either<Failure, Payment>> registerPayment(Payment payment);
}
