import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/appointment.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String providerId;
  final DateTime date;
  final String concept;
  final double totalAmount;
  final double amountPaid;
  final AppointmentStatus status;
  final String? recurringAppointmentId;

  /// Optional end time for the appointment. Null for legacy records.
  final DateTime? endTime;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.date,
    required this.concept,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
    this.recurringAppointmentId,
    this.endTime,
  });

  factory AppointmentModel.fromEntity(Appointment entity) {
    return AppointmentModel(
      id: entity.id,
      patientId: entity.patientId,
      providerId: entity.providerId,
      date: entity.date,
      concept: entity.concept,
      totalAmount: entity.totalAmount,
      amountPaid: entity.amountPaid,
      status: entity.status,
      recurringAppointmentId: entity.recurringAppointmentId,
      endTime: entity.endTime,
    );
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json, String id) {
    final rawEndTime = json['endTime'];
    return AppointmentModel(
      id: id,
      patientId: json['patientId'] as String,
      providerId: json['providerId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      concept: json['concept'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.unpaid,
      ),
      recurringAppointmentId: json['recurringAppointmentId'] as String?,
      endTime: rawEndTime != null ? (rawEndTime as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'providerId': providerId,
      'date': Timestamp.fromDate(date),
      'dateKey':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'concept': concept,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'status': status.name,
      'recurringAppointmentId': recurringAppointmentId,
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
    };
  }

  Appointment toEntity() {
    return Appointment(
      id: id,
      patientId: patientId,
      providerId: providerId,
      date: date,
      concept: concept,
      totalAmount: totalAmount,
      amountPaid: amountPaid,
      status: status,
      recurringAppointmentId: recurringAppointmentId,
      endTime: endTime,
    );
  }
}
