import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/appointment_overlap_checker.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'overlap_check_provider.g.dart';

/// Parameters for the overlap check.
///
/// Kept as a plain record to avoid Freezed overhead for a UI-only concern.
typedef OverlapCheckParams = ({
  String providerId,
  DateTime selectedDate,
  DateTime? endTime,
  String patientId,
  String? excludeAppointmentId,
});

/// Returns all appointments on [params.selectedDate] for [params.providerId]
/// that overlap with the interval [params.selectedDate, params.endTime).
///
/// The result is split into:
/// - [OverlapResult.samePatient] — overlaps with the same patient (major warning)
/// - [OverlapResult.otherPatients] — overlaps with different patients (minor warning)
///
/// Returns [OverlapResult.empty] when no date/time is selected or no overlaps exist.
@riverpod
Future<OverlapResult> overlapCheck(
  Ref ref,
  OverlapCheckParams params,
) async {
  final repository = ref.watch(ledgerRepositoryProvider);

  final appointmentsForDay = await repository.getAppointmentsForDay(
    providerId: params.providerId,
    day: params.selectedDate,
  );

  final overlapping = AppointmentOverlapChecker.findOverlaps(
    existing: appointmentsForDay,
    newStart: params.selectedDate,
    newEnd: params.endTime,
    newPatientId: params.patientId,
    excludeAppointmentId: params.excludeAppointmentId,
  );

  final samePatient =
      overlapping.where((a) => a.patientId == params.patientId).toList();
  final otherPatients =
      overlapping.where((a) => a.patientId != params.patientId).toList();

  return OverlapResult(samePatient: samePatient, otherPatients: otherPatients);
}

/// Result of an overlap check, categorised by warning severity.
class OverlapResult {
  const OverlapResult({
    required this.samePatient,
    required this.otherPatients,
  });

  const OverlapResult.empty()
      : samePatient = const [],
        otherPatients = const [];

  /// Appointments that overlap AND belong to the same patient (major warning).
  final List<Appointment> samePatient;

  /// Appointments that overlap but belong to a different patient (minor warning).
  final List<Appointment> otherPatients;

  bool get hasOverlap => samePatient.isNotEmpty || otherPatients.isNotEmpty;
}
