import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/patients/widgets/edit_patient_modal.dart';
import 'package:cobrador/presentation/patients/widgets/recurring_appointments_list.dart';
import 'package:cobrador/presentation/patients/widgets/unpaid_appointments_list.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/patient_debt_summary_card.dart';
import 'widgets/patient_header_card.dart';

class PatientDetailPage extends ConsumerWidget {
  final String patientId;
  final Patient? patientObj; // Optional object passed from list

  const PatientDetailPage({
    super.key,
    required this.patientId,
    this.patientObj,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (patientObj == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Paciente')),
        body: const Center(child: Text('Paciente no encontrado')),
      );
    }

    final patient = patientObj!;

    return Scaffold(
      appBar: _PatientDetailAppBar(
        patientName: patient.name,
        onEdit: () => showEditPatientModal(context, ref, patient),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.edgeInsetsH,
              child: PatientHeaderCard(patient: patient),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: AppSpacing.edgeInsetsH,
              child: PatientDebtSummaryCard(patient: patient),
            ),
            const SizedBox(height: AppSpacing.lg),
            UnpaidAppointmentsList(patientId: patientId),
            const SizedBox(height: AppSpacing.lg),
            RecurringAppointmentsList(patientId: patientId),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PatientDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String patientName;
  final VoidCallback onEdit;

  const _PatientDetailAppBar({required this.patientName, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(patientName),
      actions: [IconButton(icon: const Icon(Icons.edit), onPressed: onEdit)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
