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

  // Crea un turno recurrente
  Future<Either<Failure, RecurringAppointment>> createRecurringAppointment(
    RecurringAppointment recurringAppointment,
  );

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
}
