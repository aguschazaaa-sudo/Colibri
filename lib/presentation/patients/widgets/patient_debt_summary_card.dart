import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/patient.dart';

class PatientDebtSummaryCard extends StatelessWidget {
  final Patient patient;

  const PatientDebtSummaryCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    final bool hasDebt = patient.totalDebt > 0;
    final bool hasCredit = patient.balance > 0;

    Color containerColor;
    Color onContainerColor;
    String titleText;
    String amountText;

    if (hasDebt) {
      containerColor = colorScheme.secondaryContainer;
      onContainerColor = colorScheme.onSecondaryContainer;
      titleText = 'Deuda Total';
      amountText = currencyFormat.format(patient.totalDebt);
    } else if (hasCredit) {
      containerColor = colorScheme.primaryContainer;
      onContainerColor = colorScheme.onPrimaryContainer;
      titleText = 'Saldo a favor';
      amountText = currencyFormat.format(patient.balance);
    } else {
      containerColor = colorScheme.surfaceContainerHighest;
      onContainerColor = colorScheme.onSurfaceVariant;
      titleText = 'Estado de cuenta';
      amountText = 'Sin deuda';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estado Financiero',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          color: containerColor,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titleText,
                  style: textTheme.bodyLarge?.copyWith(color: onContainerColor),
                ),
                Text(
                  amountText,
                  style: textTheme.titleLarge?.copyWith(
                    color: onContainerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
