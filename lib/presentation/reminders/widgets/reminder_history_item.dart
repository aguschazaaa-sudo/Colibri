import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class ReminderHistoryItem extends StatelessWidget {
  final String patientName;
  final DateTime sentAt;
  final String status;
  final String formatStatus;

  const ReminderHistoryItem({
    super.key,
    required this.patientName,
    required this.sentAt,
    required this.status,
    required this.formatStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: AppSpacing.edgeInsetsH,
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.mark_email_read_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        patientName,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Hace ${DateTime.now().difference(sentAt).inDays} días',
        style: textTheme.bodySmall,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Text(
          formatStatus,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
