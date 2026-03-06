import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cobrador/domain/dashboard_report.dart';

/// Firestore DTO for the dashboard metrics document.
/// Stored at: `providers/{providerId}/metrics/dashboard`
class DashboardReportModel {
  final double totalToCollect;
  final double monthlyRevenue;
  final DateTime lastUpdated;

  const DashboardReportModel({
    required this.totalToCollect,
    required this.monthlyRevenue,
    required this.lastUpdated,
  });

  factory DashboardReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return DashboardReportModel.empty();

    return DashboardReportModel(
      totalToCollect: (data['totalToCollect'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (data['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          data['lastUpdated'] is Timestamp
              ? (data['lastUpdated'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory DashboardReportModel.empty() => DashboardReportModel(
    totalToCollect: 0,
    monthlyRevenue: 0,
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
  );

  DashboardReport toDomain() => DashboardReport(
    totalToCollect: totalToCollect,
    monthlyRevenue: monthlyRevenue,
    lastUpdated: lastUpdated,
  );
}
