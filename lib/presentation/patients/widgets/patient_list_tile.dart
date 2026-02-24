import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/shared/modals/create_appointment_sheet.dart';
import 'package:cobrador/presentation/shared/modals/create_payment_sheet.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PatientListTile extends StatelessWidget {
  final Patient patient;

  const PatientListTile({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasDebt = patient.totalDebt > 0;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: _PatientAvatar(name: patient.name),
        title: Text(
          patient.name,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: _PatientDebtStatus(debt: patient.totalDebt, hasDebt: hasDebt),
        trailing: _PatientQuickActions(patientId: patient.id),
        onTap: () {
          context.push('/patients/${patient.id}', extra: patient);
        },
      ),
    );
  }
}

class _PatientAvatar extends StatelessWidget {
  final String name;

  const _PatientAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(color: colorScheme.onPrimaryContainer),
      ),
    );
  }
}

class _PatientDebtStatus extends StatelessWidget {
  final double debt;
  final bool hasDebt;

  const _PatientDebtStatus({required this.debt, required this.hasDebt});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final indicatorColor = hasDebt ? colorScheme.error : colorScheme.primary;

    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Text(
      hasDebt ? 'Deuda: ${currencyFormat.format(debt)}' : 'Sin deuda',
      style: textTheme.bodyMedium?.copyWith(
        color: indicatorColor,
        fontWeight: hasDebt ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _PatientQuickActions extends StatelessWidget {
  final String patientId;

  const _PatientQuickActions({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded),
          tooltip: 'Agendar turno',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder:
                  (_) => CreateAppointmentSheet(initialPatientId: patientId),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.attach_money_rounded),
          tooltip: 'Registrar pago',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => CreatePaymentSheet(initialPatientId: patientId),
            );
          },
        ),
      ],
    );
  }
}
