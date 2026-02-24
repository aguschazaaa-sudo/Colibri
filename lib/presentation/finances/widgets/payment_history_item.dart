import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class PaymentHistoryItem extends StatelessWidget {
  final String patientName;
  final double amount;
  final DateTime date;
  final String status;

  const PaymentHistoryItem({
    super.key,
    required this.patientName,
    required this.amount,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: AppSpacing.edgeInsetsH,
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.receipt_long_rounded),
      ),
      title: Text(
        patientName,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${date.day}/${date.month}/${date.year} • $status',
        style: textTheme.bodySmall,
      ),
      trailing: Text(
        '+\$${amount.toStringAsFixed(0)}',
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
