import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card showing payment status for the appointment.
///
/// When fully paid: shows a large "Pagado" confirmation in [ColorScheme.primary].
/// When a balance is pending: shows "Saldo pendiente" with the amount in
/// [ColorScheme.error]. Always shows the total amount as secondary text.
class AppointmentFinancialCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentFinancialCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    if (appointment.totalAmount <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final currencyFmt = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );
    final pending = appointment.pendingDebt;
    final isPaid = pending <= 0;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            if (isPaid)
              _PaidConfirmation(colorScheme: colorScheme)
            else
              _PendingBalance(
                amount: currencyFmt.format(pending),
                colorScheme: colorScheme,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Total del turno: ${currencyFmt.format(appointment.totalAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidConfirmation extends StatelessWidget {
  final ColorScheme colorScheme;

  const _PaidConfirmation({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 28, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Pagado',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _PendingBalance extends StatelessWidget {
  final String amount;
  final ColorScheme colorScheme;

  const _PendingBalance({
    required this.amount,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          'Saldo pendiente del turno',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          amount,
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
