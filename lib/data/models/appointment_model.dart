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
    );
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json, String id) {
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'providerId': providerId,
      'date': Timestamp.fromDate(date),
      'concept': concept,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'status': status.name,
      'recurringAppointmentId': recurringAppointmentId,
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
    );
  }
}
