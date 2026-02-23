import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment.freezed.dart';

enum AppointmentStatus { unpaid, liquidated, cancelled }

@freezed
abstract class Appointment with _$Appointment {
  const Appointment._();

  const factory Appointment({
    required String id,
    required String patientId,
    required String providerId,
    required DateTime date,
    required String concept,
    required double totalAmount,
    @Default(0.0) double amountPaid,
    @Default(AppointmentStatus.unpaid) AppointmentStatus status,
    String? recurringAppointmentId,
  }) = _Appointment;

  double get pendingDebt => totalAmount - amountPaid;

  /// Calculates how many full months have passed since the appointment date
  /// to potentially apply monthly interest rates.
  int get monthsElapsed {
    final now = DateTime.now();
    int months = (now.year - date.year) * 12 + now.month - date.month;
    if (now.day < date.day) {
      months--;
    }
    return months < 0 ? 0 : months;
  }
}
