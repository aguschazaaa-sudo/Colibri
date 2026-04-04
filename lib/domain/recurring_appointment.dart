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
    /// Optional session duration in minutes. When null the Cloud Function falls
    /// back to the provider's [defaultSessionDurationMinutes], then to 45 min.
    int? defaultSessionDurationMinutes,
    /// List of dateKey strings (e.g. "2026-04-10") for occurrences that have
    /// been individually cancelled by the provider. The cron skips these dates
    /// and the timeline suppresses ghost cards for them.
    @Default([]) List<String> cancelledDates,
  }) = _RecurringAppointment;
}
