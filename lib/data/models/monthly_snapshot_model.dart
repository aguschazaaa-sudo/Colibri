import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/monthly_snapshot.dart';

/// Firestore DTO for a monthly revenue snapshot.
///
/// Stored at:
/// `providers/{providerId}/metrics/dashboard/monthly_snapshots/{YYYY-MM}`
///
/// Maps raw Firestore data to the [MonthlySnapshot] domain entity.
class MonthlySnapshotModel {
  final String id;
  final String month;
  final double totalRevenue;

  /// Total outstanding debt captured at snapshot time.
  /// Defaults to 0.0 for backward compatibility with older snapshots.
  final double totalDebt;
  final int year;
  final int monthIndex;
  final DateTime savedAt;

  const MonthlySnapshotModel({
    required this.id,
    required this.month,
    required this.totalRevenue,
    this.totalDebt = 0.0,
    required this.year,
    required this.monthIndex,
    required this.savedAt,
  });

  /// Constructs a [MonthlySnapshotModel] from a Firestore document snapshot.
  ///
  /// Falls back to safe defaults if the document is missing or fields are null.
  factory MonthlySnapshotModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      return MonthlySnapshotModel(
        id: doc.id,
        month: doc.id,
        totalRevenue: 0,
        year: 0,
        monthIndex: 0,
        savedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    return MonthlySnapshotModel(
      id: doc.id,
      month: data['month'] as String? ?? doc.id,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalDebt: (data['totalDebt'] as num?)?.toDouble() ?? 0.0,
      year: (data['year'] as num?)?.toInt() ?? 0,
      monthIndex: (data['monthIndex'] as num?)?.toInt() ?? 0,
      savedAt: data['savedAt'] is Timestamp
          ? (data['savedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Converts this DTO to the domain [MonthlySnapshot] entity.
  MonthlySnapshot toDomain() => MonthlySnapshot(
        id: id,
        month: month,
        totalRevenue: totalRevenue,
        totalDebt: totalDebt,
        year: year,
        monthIndex: monthIndex,
        savedAt: savedAt,
      );
}
