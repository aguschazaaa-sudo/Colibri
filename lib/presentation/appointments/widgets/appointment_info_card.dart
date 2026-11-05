import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/appointments/widgets/atoms/appointment_info_chips.dart';
import 'package:flutter/material.dart';

/// Centered row of info chips (duration + concept) for the appointment.
///
/// Acts as a thin molecule wrapper over [AppointmentInfoChips] to keep
/// the page's widget tree readable.
class AppointmentInfoCard extends StatelessWidget {
  final Appointment appointment;

  /// [patientName] kept for API compatibility but no longer displayed here —
  /// the patient name is shown in the hero header.
  const AppointmentInfoCard({
    super.key,
    required this.appointment,
    String? patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppointmentInfoChips(appointment: appointment),
    );
  }
}
