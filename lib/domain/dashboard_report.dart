import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_report.freezed.dart';

/// Pre-calculated metrics document stored under:
/// `providers/{providerId}/metrics/dashboard`
///
/// - [totalToCollect]: Sum of `totalDebt` across all patients. Stable over time.
/// - [monthlyRevenue]: Sum of payments received in the current month.
///   Reset to 0 by the cron job every 28th of the month.
/// - [lastUpdated]: Timestamp of the last write by a Cloud Function trigger.
@freezed
abstract class DashboardReport with _$DashboardReport {
  const factory DashboardReport({
    required double totalToCollect,
    required double monthlyRevenue,
    required DateTime lastUpdated,
  }) = _DashboardReport;

  /// Returns a zero-value report, useful as a default before the first
  /// cloud function has had a chance to populate the document.
  factory DashboardReport.empty() => DashboardReport(
    totalToCollect: 0,
    monthlyRevenue: 0,
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
