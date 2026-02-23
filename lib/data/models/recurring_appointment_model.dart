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

  const RecurringAppointmentModel({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.concept,
    required this.defaultAmount,
    required this.frequency,
    required this.baseDate,
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
    );
  }
}
