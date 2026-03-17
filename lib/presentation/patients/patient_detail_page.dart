import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/patients/widgets/edit_patient_modal.dart';
import 'package:cobrador/presentation/patients/widgets/recurring_appointments_list.dart';
import 'package:cobrador/presentation/patients/widgets/unpaid_appointments_list.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';

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
    if (patientObj != null) {
      return _PatientDetailScaffold(patient: patientObj!);
    }

    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Paciente')),
        body: const Center(child: Text('Usuario no autenticado')),
      );
    }

    final patientsAsync = ref.watch(patientsProvider(providerId));

    return patientsAsync.when(
      data: (patients) {
        final patient = patients.cast<Patient?>().firstWhere(
          (p) => p?.id == patientId,
          orElse: () => null,
        );

        if (patient == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle de Paciente')),
            body: const Center(child: Text('Paciente no encontrado')),
          );
        }

        return _PatientDetailScaffold(patient: patient);
      },
      loading:
          () => Scaffold(
            appBar: AppBar(title: const Text('Cargando...')),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, st) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: $e')),
          ),
    );
  }
}

class _PatientDetailScaffold extends ConsumerWidget {
  final Patient patient;

  const _PatientDetailScaffold({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            UnpaidAppointmentsList(patientId: patient.id),
            const SizedBox(height: AppSpacing.lg),
            RecurringAppointmentsList(patientId: patient.id),
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
