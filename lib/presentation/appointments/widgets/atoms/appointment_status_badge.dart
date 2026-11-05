import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Chip that displays the appointment status with a semantic color.
class AppointmentStatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const AppointmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, bgColor, fgColor) = switch (status) {
      AppointmentStatus.scheduled => (
          'Agendado',
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      AppointmentStatus.unpaid => (
          'Sin pagar',
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      AppointmentStatus.liquidated => (
          'Pagado',
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      AppointmentStatus.cancelled => (
          'Cancelado',
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
    };

    return Chip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
      ),
      backgroundColor: bgColor,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 0,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
