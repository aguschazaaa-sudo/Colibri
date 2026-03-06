import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/shared/modals/create_appointment_sheet.dart';
import 'package:cobrador/presentation/shared/modals/create_payment_sheet.dart';
import 'package:cobrador/presentation/shared/modals/create_recurring_appointment_sheet.dart';
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
        subtitle: _PatientDebtStatus(
          debt: patient.totalDebt,
          balance: patient.balance,
          hasDebt: hasDebt,
        ),
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
  final double balance;
  final bool hasDebt;

  const _PatientDebtStatus({
    required this.debt,
    required this.balance,
    required this.hasDebt,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    final bool hasCredit = balance > 0;

    Color indicatorColor;
    String text;
    FontWeight fontWeight;

    if (hasDebt) {
      indicatorColor = colorScheme.secondary;
      text = 'Deuda: ${currencyFormat.format(debt)}';
      fontWeight = FontWeight.bold;
    } else if (hasCredit) {
      indicatorColor = colorScheme.primary;
      text = 'A favor: ${currencyFormat.format(balance)}';
      fontWeight = FontWeight.bold;
    } else {
      indicatorColor = colorScheme.primary;
      text = 'Sin deuda';
      fontWeight = FontWeight.normal;
    }

    return Text(
      text,
      style: textTheme.bodyMedium?.copyWith(
        color: indicatorColor,
        fontWeight: fontWeight,
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
          icon: const Icon(Icons.event_repeat_rounded),
          tooltip: 'Abono recurrente',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder:
                  (_) => CreateRecurringAppointmentSheet(
                    initialPatientId: patientId,
                  ),
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
