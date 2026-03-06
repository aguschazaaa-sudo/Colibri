import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_appointment.freezed.dart';

enum Frequency { weekly, biweekly, monthly }

@freezed
abstract class RecurringAppointment with _$RecurringAppointment {
  const factory RecurringAppointment({
    required String id,
    required String patientId,
    required String providerId,
    required String concept,
    required double defaultAmount,
    required Frequency frequency,
    required DateTime baseDate,
    @Default(true) bool active,
    DateTime? endDate,
  }) = _RecurringAppointment;
}
