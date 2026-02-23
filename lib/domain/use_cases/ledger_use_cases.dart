import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/payment.dart';

/// Resultado de aplicar un pago
class PaymentResult {
  final List<Appointment> updatedAppointments;
  final Patient updatedPatient;

  PaymentResult({
    required this.updatedAppointments,
    required this.updatedPatient,
  });
}

/// Caso de uso matemático puro para calcular intereses compuestos
class CalculateInterestUseCase {
  /// Calcula cómo quedaría un turno aplicando interés compuesto
  /// sobre los meses enteros de atraso.
  /// Ej: 100 ARS a 10% mensual tras 2 meses -> 121 ARS
  Appointment execute(Appointment appointment, double monthlyInterestRate) {
    if (appointment.status != AppointmentStatus.unpaid) {
      return appointment;
    }

    final months = appointment.monthsElapsed;
    if (months <= 0 || monthlyInterestRate <= 0.0) {
      return appointment;
    }

    double currentTotal = appointment.totalAmount;

    // Interés compuesto
    for (int i = 0; i < months; i++) {
      currentTotal += currentTotal * monthlyInterestRate;
    }

    return appointment.copyWith(totalAmount: currentTotal);
  }
}

/// Caso de uso matemático puro para distribuir el dinero de un pago (FIFO)
class ApplyPaymentUseCase {
  /// Recibe un pago, la lista de todos los turnos del paciente y al paciente mismo.
  /// Devuelve los turnos saldados y el nuevo saldo del paciente.
  PaymentResult execute(
    Payment payment,
    List<Appointment> allAppointments,
    Patient patient,
  ) {
    // 1. Filtrar solo los impagos y ordenarlos por fecha (Los más viejos primero -> FIFO)
    final unpaidAppointments =
        allAppointments
            .where((a) => a.status == AppointmentStatus.unpaid)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    double remainingMoney = payment.amount;
    final List<Appointment> updatedAppointments = [];

    // 2. Si el pago especifica un turno, pagamos ese primero
    if (payment.appointmentId != null) {
      final targetIndex = unpaidAppointments.indexWhere(
        (a) => a.id == payment.appointmentId,
      );

      if (targetIndex != -1) {
        final target = unpaidAppointments[targetIndex];
        final debt = target.pendingDebt;

        if (remainingMoney >= debt) {
          // Cubre todo el turno específico
          updatedAppointments.add(
            target.copyWith(
              amountPaid: target.totalAmount,
              status: AppointmentStatus.liquidated,
            ),
          );
          remainingMoney -= debt;
        } else {
          // Cubre una parte del turno específico
          updatedAppointments.add(
            target.copyWith(amountPaid: target.amountPaid + remainingMoney),
          );
          remainingMoney = 0;
        }

        // Lo sacamos de la lista genérica para no volver a pagarlo en FIFO
        unpaidAppointments.removeAt(targetIndex);
      }
    }

    // 3. FIFO para el resto del dinero
    for (final appt in unpaidAppointments) {
      if (remainingMoney <= 0) {
        // Mantenemos el turno original en la lista final si no lo tocamos
        updatedAppointments.add(appt);
        continue;
      }

      final debt = appt.pendingDebt;
      if (remainingMoney >= debt) {
        // Liquida este turno viejo
        updatedAppointments.add(
          appt.copyWith(
            amountPaid: appt.totalAmount,
            status: AppointmentStatus.liquidated,
          ),
        );
        remainingMoney -= debt;
      } else {
        // Lo paga parcialmente y nos quedamos sin dinero
        updatedAppointments.add(
          appt.copyWith(amountPaid: appt.amountPaid + remainingMoney),
        );
        remainingMoney = 0;
      }
    }

    // Calcular la deuda total restante después del pago para actualizar al paciente
    final newTotalDebt = updatedAppointments
        .where((a) => a.status == AppointmentStatus.unpaid)
        .fold(0.0, (sum, a) => sum + a.pendingDebt);

    // Actualizar el balance (saldo a favor) si sobró dinero
    final newBalance = patient.balance + remainingMoney;

    return PaymentResult(
      updatedAppointments: updatedAppointments,
      updatedPatient: patient.copyWith(
        totalDebt: newTotalDebt,
        balance: newBalance,
      ),
    );
  }
}
