import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/patient.dart';

/// Data model for mapping Firestore data to domain Patient entity.
class PatientModel {
  final String id;
  final String providerId;
  final String name;
  final String phoneNumber;
  final double totalDebt;
  final double balance;
  final DateTime createdAt;

  const PatientModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.phoneNumber,
    required this.totalDebt,
    required this.balance,
    required this.createdAt,
  });

  /// Map from Domain to Model
  factory PatientModel.fromEntity(Patient entity) {
    return PatientModel(
      id: entity.id,
      providerId: entity.providerId,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      totalDebt: entity.totalDebt,
      balance: entity.balance,
      createdAt: entity.createdAt,
    );
  }

  /// Map from Firestore JSON to Model
  factory PatientModel.fromJson(Map<String, dynamic> json, String id) {
    return PatientModel(
      id: id,
      providerId: json['providerId'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      totalDebt: (json['totalDebt'] as num).toDouble(),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Map from Model to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'name': name,
      'phoneNumber': phoneNumber,
      'totalDebt': totalDebt,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Map from Model to Domain Entity
  Patient toEntity() {
    return Patient(
      id: id,
      providerId: providerId,
      name: name,
      phoneNumber: phoneNumber,
      totalDebt: totalDebt,
      balance: balance,
      createdAt: createdAt,
    );
  }
}
