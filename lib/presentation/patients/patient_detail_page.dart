import 'package:cobrador/domain/patient.dart';
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
      appBar: _PatientDetailAppBar(patientName: patient.name),
      body: SingleChildScrollView(
        padding: AppSpacing.edgeInsetsH.copyWith(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatientHeaderCard(patient: patient),
            const SizedBox(height: AppSpacing.lg),
            PatientDebtSummaryCard(patient: patient),
            const SizedBox(height: AppSpacing.lg),
            const _PatientHistorySection(),
          ],
        ),
      ),
    );
  }
}

class _PatientDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String patientName;

  const _PatientDetailAppBar({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(patientName),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Editar paciente
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PatientHistorySection extends StatelessWidget {
  const _PatientHistorySection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Historial (En construcción)',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Funcionalidad de historial del libro mayor en proceso.',
            ),
          ),
        ),
      ],
    );
  }
}
