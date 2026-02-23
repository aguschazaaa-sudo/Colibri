import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/payment.dart';

class PaymentModel {
  final String id;
  final String patientId;
  final String providerId;
  final String? appointmentId;
  final double amount;
  final DateTime date;

  const PaymentModel({
    required this.id,
    required this.patientId,
    required this.providerId,
    this.appointmentId,
    required this.amount,
    required this.date,
  });

  factory PaymentModel.fromEntity(Payment entity) {
    return PaymentModel(
      id: entity.id,
      patientId: entity.patientId,
      providerId: entity.providerId,
      appointmentId: entity.appointmentId,
      amount: entity.amount,
      date: entity.date,
    );
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json, String id) {
    return PaymentModel(
      id: id,
      patientId: json['patientId'] as String,
      providerId: json['providerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      appointmentId: json['appointmentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'providerId': providerId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      if (appointmentId != null) 'appointmentId': appointmentId,
    };
  }

  Payment toEntity() {
    return Payment(
      id: id,
      patientId: patientId,
      providerId: providerId,
      appointmentId: appointmentId,
      amount: amount,
      date: date,
    );
  }
}
