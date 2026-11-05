import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Card showing the patient's global account balance, differentiated from
/// the appointment-specific financial card.
///
/// Displays one of three states:
/// - [ColorScheme.errorContainer]: patient has outstanding debt.
/// - [ColorScheme.tertiaryContainer]: patient has credit in their favor.
/// - [ColorScheme.surfaceContainerHighest]: patient is fully settled.
///
/// When [patient] is null the card renders a skeleton loading state.
class AppointmentPatientBalanceCard extends StatelessWidget {
  final Patient? patient;

  const AppointmentPatientBalanceCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final isLoading = patient == null;

    // Provide a dummy patient for the skeleton so layout dimensions are stable.
    final effective = patient ??
        Patient(
          id: 'dummy',
          providerId: 'dummy',
          name: 'Nombre Apellido',
          phoneNumber: '1100000000',
          totalDebt: 12000,
          balance: 0,
          createdAt: DateTime(2024),
        );

    return Skeletonizer(
      enabled: isLoading,
      child: _PatientBalanceContent(patient: effective),
    );
  }
}

class _PatientBalanceContent extends StatelessWidget {
  final Patient patient;

  const _PatientBalanceContent({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SectionDivider(label: 'Cuenta del paciente'),
        const SizedBox(height: AppSpacing.sm),
        _BalanceCard(patient: patient),
      ],
    );
  }
}

/// Divider row with a centered label, using two [Divider] widgets.
class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Patient patient;

  const _BalanceCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currencyFmt = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    final (bg, fg, title, amount) = switch (patient) {
      _ when patient.totalDebt > 0 => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
          'Saldo pendiente',
          currencyFmt.format(patient.totalDebt),
        ),
      _ when patient.balance > 0 => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
          'Saldo a favor',
          currencyFmt.format(patient.balance),
        ),
      _ => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
          'Al día',
          '-',
        ),
    };

    return Card(
      elevation: 0,
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(color: fg),
            ),
            Text(
              amount,
              style: textTheme.titleMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
