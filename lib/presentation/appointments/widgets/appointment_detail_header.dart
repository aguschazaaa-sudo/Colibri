import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Full-width hero banner at the top of the appointment detail page.
///
/// Background uses [ColorScheme.primaryContainer] with rounded bottom corners
/// to create a "ticket" feel. Displays the status icon, a status headline,
/// and the patient's name.
class AppointmentDetailHeader extends StatelessWidget {
  final String patientName;
  final AppointmentStatus status;

  const AppointmentDetailHeader({
    super.key,
    required this.patientName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, headline) = switch (status) {
      AppointmentStatus.scheduled => (
          Icons.event_available_rounded,
          'Turno Confirmado',
        ),
      AppointmentStatus.unpaid => (
          Icons.event_available_rounded,
          'Turno Realizado',
        ),
      AppointmentStatus.liquidated => (
          Icons.event_available_rounded,
          'Turno Pagado',
        ),
      AppointmentStatus.cancelled => (
          Icons.event_busy_rounded,
          'Turno Cancelado',
        ),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            headline,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            patientName,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
