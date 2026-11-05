import 'package:freezed_annotation/freezed_annotation.dart';

part 'monthly_snapshot.freezed.dart';

/// Represents a monthly revenue snapshot captured at the end of each billing
/// cycle, before the `monthlyRevenue` counter is reset.
///
/// Stored at:
/// `providers/{providerId}/metrics/dashboard/monthly_snapshots/{YYYY-MM}`
@freezed
abstract class MonthlySnapshot with _$MonthlySnapshot {
  const factory MonthlySnapshot({
    /// Document ID — equals [month] (e.g. "2026-03").
    required String id,

    /// ISO-format month key: "YYYY-MM".
    required String month,

    /// Total revenue collected during this month before reset.
    required double totalRevenue,

    /// Total outstanding debt captured at snapshot time (from
    /// `providers/{providerId}/metrics/dashboard.totalToCollect`).
    /// Defaults to 0.0 for backward compatibility with snapshots written
    /// before this field was introduced.
    @Default(0.0) double totalDebt,

    /// Calendar year (e.g. 2026).
    required int year,

    /// Zero-based month index (0 = January … 11 = December).
    required int monthIndex,

    /// Server timestamp when the snapshot was written.
    required DateTime savedAt,
  }) = _MonthlySnapshot;
}
