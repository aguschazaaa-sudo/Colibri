import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Horizontal row of info chips: duration (if present) and concept.
///
/// Uses native Material 3 [Chip] with [ColorScheme.secondaryContainer].
class AppointmentInfoChips extends StatelessWidget {
  final Appointment appointment;

  const AppointmentInfoChips({super.key, required this.appointment});

  String? _durationLabel() {
    final duration = appointment.duration;
    if (duration == null || duration.inMinutes <= 0) return null;
    final h = duration.inMinutes ~/ 60;
    final m = duration.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final durationLabel = _durationLabel();
    final conceptLabel =
        appointment.concept.isEmpty ? 'Consulta' : appointment.concept;

    final chipBg = colorScheme.secondaryContainer;
    final chipFg = colorScheme.onSecondaryContainer;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (durationLabel != null)
          _InfoChip(
            icon: Icons.timer_outlined,
            label: durationLabel,
            backgroundColor: chipBg,
            foregroundColor: chipFg,
          ),
        _InfoChip(
          icon: Icons.notes_rounded,
          label: conceptLabel,
          backgroundColor: chipBg,
          foregroundColor: chipFg,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: foregroundColor),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: foregroundColor,
          ),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
    );
  }
}
