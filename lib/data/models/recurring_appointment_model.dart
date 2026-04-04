import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/recurring_appointment.dart';

class RecurringAppointmentModel {
  final String id;
  final String patientId;
  final String providerId;
  final String concept;
  final double defaultAmount;
  final Frequency frequency;
  final DateTime baseDate;
  final DateTime? endDate;
  final bool active;

  /// Optional session duration in minutes. Null means "use provider default".
  final int? defaultSessionDurationMinutes;

  /// Dates (format "yyyy-MM-dd") for which this recurring appointment has been
  /// individually cancelled by the provider.
  final List<String> cancelledDates;

  const RecurringAppointmentModel({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.concept,
    required this.defaultAmount,
    required this.frequency,
    required this.baseDate,
    required this.active,
    this.endDate,
    this.defaultSessionDurationMinutes,
    this.cancelledDates = const [],
  });

  factory RecurringAppointmentModel.fromEntity(RecurringAppointment entity) {
    return RecurringAppointmentModel(
      id: entity.id,
      patientId: entity.patientId,
      providerId: entity.providerId,
      concept: entity.concept,
      defaultAmount: entity.defaultAmount,
      frequency: entity.frequency,
      baseDate: entity.baseDate,
      active: entity.active,
      endDate: entity.endDate,
      defaultSessionDurationMinutes: entity.defaultSessionDurationMinutes,
      cancelledDates: entity.cancelledDates,
    );
  }

  factory RecurringAppointmentModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return RecurringAppointmentModel(
      id: id,
      patientId: json['patientId'] as String,
      providerId: json['providerId'] as String,
      concept: json['concept'] as String,
      defaultAmount: (json['defaultAmount'] as num).toDouble(),
      frequency: Frequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => Frequency.monthly, // default fail-safe
      ),
      baseDate: (json['baseDate'] as Timestamp).toDate(),
      active: json['active'] as bool? ?? true,
      endDate:
          json['endDate'] != null
              ? (json['endDate'] as Timestamp).toDate()
              : null,
      defaultSessionDurationMinutes:
          (json['defaultSessionDurationMinutes'] as num?)?.toInt(),
      cancelledDates: List<String>.from(
        json['cancelledDates'] as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'providerId': providerId,
      'concept': concept,
      'defaultAmount': defaultAmount,
      'frequency': frequency.name,
      'baseDate': Timestamp.fromDate(baseDate),
      'active': active,
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (defaultSessionDurationMinutes != null)
        'defaultSessionDurationMinutes': defaultSessionDurationMinutes,
      'cancelledDates': cancelledDates,
    };
  }

  RecurringAppointment toEntity() {
    return RecurringAppointment(
      id: id,
      patientId: patientId,
      providerId: providerId,
      concept: concept,
      defaultAmount: defaultAmount,
      frequency: frequency,
      baseDate: baseDate,
      active: active,
      endDate: endDate,
      defaultSessionDurationMinutes: defaultSessionDurationMinutes,
      cancelledDates: cancelledDates,
    );
  }
}
