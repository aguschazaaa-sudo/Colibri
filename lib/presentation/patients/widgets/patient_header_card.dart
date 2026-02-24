import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

import '../../../../domain/patient.dart';

class PatientHeaderCard extends StatelessWidget {
  final Patient patient;

  const PatientHeaderCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _ProfileAvatar(name: patient.name),
            const SizedBox(height: AppSpacing.sm),
            _ProfileName(name: patient.name),
            const SizedBox(height: AppSpacing.xs),
            _ProfileContactLine(text: 'Tel: \$${patient.phoneNumber}'),
            if (patient.email != null && patient.email!.isNotEmpty)
              _ProfileContactLine(text: 'Email: ${patient.email}'),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;

  const _ProfileAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 32,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initial,
        style: textTheme.headlineMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ProfileName extends StatelessWidget {
  final String name;

  const _ProfileName({required this.name});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      name,
      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _ProfileContactLine extends StatelessWidget {
  final String text;

  const _ProfileContactLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(text, style: textTheme.bodyMedium);
  }
}
