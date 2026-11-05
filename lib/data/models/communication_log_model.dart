import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/communication_log.dart';

double _parseDebt(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
  return 0;
}

class CommunicationLogModel {
  final String id;
  final String patientId;
  final String providerId;
  final String messageId;
  final DateTime sentAt;
  final String status;
  final double totalDebtAtThatTime;
  final String? patientName;
  final String? messageType;
  final Map<String, String>? variables;

  const CommunicationLogModel({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.messageId,
    required this.sentAt,
    required this.status,
    required this.totalDebtAtThatTime,
    this.patientName,
    this.messageType,
    this.variables,
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
      patientName: entity.patientName,
      messageType: entity.messageType,
      variables: entity.variables,
    );
  }

  factory CommunicationLogModel.fromJson(Map<String, dynamic> json, String id) {
    return CommunicationLogModel(
      id: id,
      patientId: json['patientId'] as String,
      providerId: json['providerId'] as String,
      messageId: (json['messageId'] as String?) ?? '',
      sentAt: (json['sentAt'] as Timestamp).toDate(),
      status: json['status'] as String,
      totalDebtAtThatTime: _parseDebt(json['totalDebtAtThatTime']),
      patientName: json['patientName'] as String?,
      messageType: json['messageType'] as String?,
      variables: (json['variables'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
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
      if (patientName != null) 'patientName': patientName,
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
      patientName: patientName,
      messageType: messageType,
      variables: variables,
    );
  }
}
