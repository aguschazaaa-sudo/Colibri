import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/communication_log.dart';

class CommunicationLogModel {
  final String id;
  final String patientId;
  final String providerId;
  final String messageId;
  final DateTime sentAt;
  final String status;
  final double totalDebtAtThatTime;

  const CommunicationLogModel({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.messageId,
    required this.sentAt,
    required this.status,
    required this.totalDebtAtThatTime,
  });

  factory CommunicationLogModel.fromEntity(CommunicationLog entity) {
    return CommunicationLogModel(
      id: entity.id,
      patientId: entity.patientId,
      providerId: entity.providerId,
      messageId: entity.messageId,
      sentAt: entity.sentAt,
      status: entity.status,
      totalDebtAtThatTime: entity.totalDebtAtThatTime,
    );
  }

  factory CommunicationLogModel.fromJson(Map<String, dynamic> json, String id) {
    return CommunicationLogModel(
      id: id,
      patientId: json['patientId'] as String,
      providerId: json['providerId'] as String,
      messageId: json['messageId'] as String,
      sentAt: (json['sentAt'] as Timestamp).toDate(),
      status: json['status'] as String,
      totalDebtAtThatTime: (json['totalDebtAtThatTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'providerId': providerId,
      'messageId': messageId,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status,
      'totalDebtAtThatTime': totalDebtAtThatTime,
    };
  }

  CommunicationLog toEntity() {
    return CommunicationLog(
      id: id,
      patientId: patientId,
      providerId: providerId,
      messageId: messageId,
      sentAt: sentAt,
      status: status,
      totalDebtAtThatTime: totalDebtAtThatTime,
    );
  }
}
