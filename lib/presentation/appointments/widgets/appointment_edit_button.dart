import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/shared/modals/create_appointment_sheet.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Fixed bottom edit button rendered via [Scaffold.bottomNavigationBar].
class AppointmentEditButton extends StatelessWidget {
  final Appointment appointment;

  const AppointmentEditButton({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + bottomPadding,
      ),
      child: FilledButton.icon(
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Editar turno'),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => CreateAppointmentSheet(
            initialPatientId: appointment.patientId,
            existingAppointment: appointment,
          ),
        ),
      ),
    );
  }
}
