import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/cancel_recurring_occurrence_controller.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Maps [Frequency] to a user-facing Spanish label.
extension FrequencyLabel on Frequency {
  String get label => switch (this) {
        Frequency.weekly => 'Semanal',
        Frequency.biweekly => 'Quincenal',
        Frequency.monthly => 'Mensual',
      };
}

/// Atom: a "ghost" card representing a [RecurringAppointment] that has no
/// confirmed appointment on the selected day yet.
///
/// Rendered at reduced opacity with a dashed-style border to visually
/// distinguish projected occurrences from confirmed appointments.
///
/// Shows a trash icon button in the top-right corner to cancel this single
/// occurrence. Tapping the card body navigates to the patient detail page.
class ProjectedAppointmentCard extends ConsumerStatefulWidget {
  const ProjectedAppointmentCard({
    super.key,
    required this.rule,
    required this.providerId,
    required this.dateKey,
    this.patientName,
    this.width,
  });

  final RecurringAppointment rule;
  final String providerId;

  /// dateKey string in "yyyy-MM-dd" format for the projected occurrence.
  final String dateKey;

  /// Resolved patient name; shows 'Paciente' while loading or unknown.
  final String? patientName;

  /// When null the card fills its parent constraint (timeline mode).
  final double? width;

  @override
  ConsumerState<ProjectedAppointmentCard> createState() =>
      _ProjectedAppointmentCardState();
}

class _ProjectedAppointmentCardState
    extends ConsumerState<ProjectedAppointmentCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rule = widget.rule;

    ref.listen(cancelRecurringOccurrenceControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is AsyncError && previous is! AsyncError) {
        final msg = (next.error as Exception?)?.toString() ?? 'Error al cancelar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _handleCancelOccurrence,
            ),
          ),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión cancelada')),
        );
      }
    });

    final time =
        '${rule.baseDate.hour.toString().padLeft(2, '0')}:'
        '${rule.baseDate.minute.toString().padLeft(2, '0')}';

    final cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.repeat_rounded,
              size: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              time,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.patientName ?? 'Paciente',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          rule.concept,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        _FrequencyChip(frequency: rule.frequency),
      ],
    );

    return GestureDetector(
      onTap: () => context.push('/patients/${rule.patientId}'),
      child: Opacity(
        opacity: 0.55,
        child: Stack(
          children: [
            Container(
              width: widget.width,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: cardBody,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: 'Cancelar esta sesión',
                onPressed: _handleCancelOccurrence,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancelOccurrence() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar esta sesión?'),
        content: const Text(
          'Solo se cancelará esta ocurrencia. La regla recurrente seguirá activa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(cancelRecurringOccurrenceControllerProvider.notifier)
        .cancelOccurrence(
          providerId: widget.providerId,
          patientId: widget.rule.patientId,
          recurringAppointmentId: widget.rule.id,
          dateKey: widget.dateKey,
        );

    if (!context.mounted) return;
    final state = ref.read(cancelRecurringOccurrenceControllerProvider);
    state.whenOrNull(
      error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _handleCancelOccurrence,
          ),
        ),
      ),
      data: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cancelada.')),
      ),
    );
  }
}

// -- Atom: frequency chip ----------------------------------------------------

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({required this.frequency});

  final Frequency frequency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            size: 10,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            frequency.label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
