import 'appointment.dart';

/// Pure domain utility for detecting appointment time overlaps.
///
/// Overlap rules:
/// - If BOTH appointments have [Appointment.endTime], overlaps when the
///   half-open intervals [start1, end1) and [start2, end2) intersect.
/// - If the existing appointment has NO [endTime], overlaps when its start
///   time is exactly equal to [newStart].
/// - Cancelled appointments are never considered overlapping.
class AppointmentOverlapChecker {
  AppointmentOverlapChecker._();

  /// Returns the subset of [existing] appointments that overlap with a new
  /// appointment starting at [newStart] and optionally ending at [newEnd].
  ///
  /// Pass [excludeAppointmentId] in edit mode to avoid reporting the
  /// appointment being edited as its own overlap.
  static List<Appointment> findOverlaps({
    required List<Appointment> existing,
    required DateTime newStart,
    required DateTime? newEnd,
    required String newPatientId,
    String? excludeAppointmentId,
  }) {
    return existing.where((a) {
      // Never flag cancelled appointments.
      if (a.status == AppointmentStatus.cancelled) return false;

      // Skip self when editing.
      if (excludeAppointmentId != null && a.id == excludeAppointmentId) {
        return false;
      }

      if (a.endTime != null && newEnd != null) {
        // Both have endTime — check [start1, end1) ∩ [start2, end2) ≠ ∅.
        // Two half-open intervals [s1, e1) and [s2, e2) overlap iff s1 < e2 && s2 < e1.
        return newStart.isBefore(a.endTime!) && a.date.isBefore(newEnd);
      } else {
        // Existing has no endTime (legacy) — overlap only on exact start match.
        return a.date == newStart;
      }
    }).toList();
  }
}
