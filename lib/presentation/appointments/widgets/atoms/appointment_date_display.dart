import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Floating date block displayed below the hero header.
///
/// Shows the day of the week, the full date (e.g. "21 de marzo") and the
/// time prominently, with no card or border — text floats on the surface.
class AppointmentDateDisplay extends StatelessWidget {
  final DateTime date;

  const AppointmentDateDisplay({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final dayOfWeek =
        DateFormat('EEEE', 'es').format(date).toUpperCase();
    final fullDate = DateFormat("d 'de' MMMM", 'es').format(date);
    final time = DateFormat('HH:mm', 'es').format(date);

    return Column(
      children: [
        Text(
          dayOfWeek,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          fullDate,
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$time hs',
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
