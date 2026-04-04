import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/presentation/providers/cancel_recurring_occurrence_controller.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Molecule: card displaying a single appointment — used both in the legacy
/// horizontal strip and the new vertical day timeline.
///
/// Shows time, patient name, concept, outstanding amount and a quick-pay button.
/// Tapping the card navigates to [AppointmentDetailPage].
///
/// When [inTimeline] is `true` the card removes its internal [Spacer] and uses
/// [MainAxisSize.min] so the parent [Positioned] controls the card height.
/// When [showEstimatedBadge] is `true` a small "~Xmin estimado" chip is shown
/// (used when [appointment.endTime] is null and duration is inferred).
class TodayAppointmentCard extends ConsumerStatefulWidget {
  final Appointment appointment;

  /// When true, the widget renders skeleton-safe placeholder data and
  /// suppresses any live provider calls.
  final bool isSkeleton;

  /// When true, removes the internal [Spacer] so the parent [Positioned]
  /// in the timeline controls the card height.
  final bool inTimeline;

  /// When true, shows a small estimated-duration badge.
  /// Typically set when [appointment.endTime] is null.
  final bool showEstimatedBadge;

  /// Overrides the fixed 220dp width. Pass `null` in timeline mode so the
  /// parent [Positioned] controls width.
  final double? width;

  const TodayAppointmentCard({
    super.key,
    required this.appointment,
    this.isSkeleton = false,
    this.inTimeline = false,
    this.showEstimatedBadge = false,
    this.width = 220,
  });

  @override
  ConsumerState<TodayAppointmentCard> createState() =>
      _TodayAppointmentCardState();
}

class _TodayAppointmentCardState extends ConsumerState<TodayAppointmentCard> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for cancel-occurrence results and show snackbars
    if (widget.inTimeline &&
        widget.appointment.recurringAppointmentId != null) {
      ref.listen(cancelRecurringOccurrenceControllerProvider, (previous, next) {
        if (!mounted) return;
        if (next is AsyncError && previous is! AsyncError) {
          final msg =
              (next.error as Exception?)?.toString() ?? 'Error al cancelar';
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
    }
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appointment = widget.appointment;

    final patientsAsync = widget.isSkeleton
        ? null
        : ref.watch(patientsProvider(appointment.providerId));

    final patientName = widget.isSkeleton
        ? appointment.patientId
        : (patientsAsync?.valueOrNull
                ?.where((p) => p.id == appointment.patientId)
                .firstOrNull
                ?.name ??
            'Cargando...');

    final isPaid = appointment.status == AppointmentStatus.liquidated;
    final isScheduled = appointment.status == AppointmentStatus.scheduled;
    final time =
        '${appointment.date.hour.toString().padLeft(2, '0')}:${appointment.date.minute.toString().padLeft(2, '0')}';

    final cardContent = widget.inTimeline
        ? null // handled below via LayoutBuilder
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              _CardTopRow(
                time: time,
                isPaid: isPaid,
                isScheduled: isScheduled,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                patientName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPaid
                      ? colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6)
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                appointment.concept,
                style: textTheme.bodySmall?.copyWith(
                  color: isPaid
                      ? colorScheme.outline
                      : colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.showEstimatedBadge) ...[
                const SizedBox(height: AppSpacing.xs),
                _EstimatedDurationBadge(appointment: appointment),
              ],
              const Spacer(),
              const SizedBox(height: AppSpacing.xs),
              _CardBottomRow(
                appointment: appointment,
                isPaid: isPaid,
                isSubmitting: _isSubmitting,
                onPayPressed: _handlePayment,
              ),
            ],
          );

    Widget container({required Widget child}) => GestureDetector(
      onTap: widget.isSkeleton
          ? null
          : () => context.push('/appointments/${appointment.id}', extra: appointment),
      child: Container(
        width: widget.width,
        padding: EdgeInsets.symmetric(
          horizontal: widget.inTimeline ? AppSpacing.sm : AppSpacing.md,
          vertical: widget.inTimeline ? AppSpacing.xs : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isPaid
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : isScheduled
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: isPaid
                ? Colors.transparent
                : isScheduled
                    ? colorScheme.secondary.withValues(alpha: 0.2)
                    : colorScheme.outlineVariant,
          ),
        ),
        child: child,
      ),
    );

    if (!widget.inTimeline) {
      return container(child: cardContent!);
    }

    // LayoutBuilder OUTSIDE the container so height = outer (Positioned) height,
    // not the inner padded height.
    return LayoutBuilder(
      builder: (context, constraints) {
        return container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildTimelineChildren(
              height: constraints.maxHeight,
              time: time,
              patientName: patientName,
              isPaid: isPaid,
              isScheduled: isScheduled,
              appointment: appointment,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ),
        );
      },
    );
  }

  /// Selects which children to render based on available [height].
  ///
  /// Progressive disclosure (based on outer/Positioned height):
  /// - `< 52`: combined row only (time + name + icon)
  /// - `52..89`: combined row + bottom row (amount + Cobrar)
  /// - `>= 90`: combined row + concept + bottom row
  List<Widget> _buildTimelineChildren({
    required double height,
    required String time,
    required String patientName,
    required bool isPaid,
    required bool isScheduled,
    required Appointment appointment,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isRecurring = appointment.recurringAppointmentId != null;

    // Combined row: [time  patientName ... statusIcon  (trashIcon)]
    final combinedRow = _CardTopRow(
      time: time,
      isPaid: isPaid,
      isScheduled: isScheduled,
      patientName: patientName,
      onCancelOccurrence: isRecurring ? _handleCancelOccurrence : null,
    );

    // Minimal: combined row only
    if (height < 52) {
      return [combinedRow];
    }

    // Standard: combined row + bottom row (amount + Cobrar)
    if (height < 90) {
      return [
        combinedRow,
        const Spacer(),
        _CardBottomRow(
          appointment: appointment,
          isPaid: isPaid,
          isSubmitting: _isSubmitting,
          onPayPressed: _handlePayment,
        ),
      ];
    }

    // Full: combined row + concept + bottom row
    return [
      combinedRow,
      const SizedBox(height: AppSpacing.xs),
      Text(
        appointment.concept,
        style: textTheme.bodySmall?.copyWith(
          color: isPaid ? colorScheme.outline : colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const Spacer(),
      _CardBottomRow(
        appointment: appointment,
        isPaid: isPaid,
        isSubmitting: _isSubmitting,
        onPayPressed: _handlePayment,
      ),
    ];
  }

  Future<void> _handleCancelOccurrence() async {
    final appointment = widget.appointment;
    final recurringId = appointment.recurringAppointmentId;
    if (recurringId == null) return;

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

    final date = appointment.date;
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await ref
        .read(cancelRecurringOccurrenceControllerProvider.notifier)
        .cancelOccurrence(
          providerId: appointment.providerId,
          patientId: appointment.patientId,
          recurringAppointmentId: recurringId,
          dateKey: dateKey,
          existingAppointmentId: appointment.id,
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

  Future<void> _handlePayment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final appointment = widget.appointment;
      final payment = Payment(
        id: '',
        patientId: appointment.patientId,
        providerId: appointment.providerId,
        amount: appointment.totalAmount - appointment.amountPaid,
        date: DateTime.now(),
        appointmentId: appointment.id,
        idempotencyKey: 'pay_${appointment.id}',
      );

      await ref
          .read(
            ledgerProvider(
              providerId: appointment.providerId,
              patientId: appointment.patientId,
            ).notifier,
          )
          .registerPayment(payment);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ── Atom: top row with time + status icon ─────────────────────────────────────

class _CardTopRow extends StatelessWidget {
  final String time;
  final bool isPaid;
  final bool isScheduled;
  final String? patientName;

  /// When non-null, a trash icon button is shown that calls this callback.
  /// Only provided in timeline mode when [appointment.recurringAppointmentId]
  /// is non-null.
  final VoidCallback? onCancelOccurrence;

  const _CardTopRow({
    required this.time,
    required this.isPaid,
    required this.isScheduled,
    this.patientName,
    this.onCancelOccurrence,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          time,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPaid ? colorScheme.outline : colorScheme.primary,
            decoration: isPaid ? TextDecoration.lineThrough : null,
          ),
        ),
        if (patientName != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              patientName!,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isPaid
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (patientName == null) const Spacer(),
        if (isPaid)
          Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600)
        else if (isScheduled)
          Icon(Icons.event_outlined, size: 16, color: colorScheme.secondary)
        else
          Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
        if (onCancelOccurrence != null) ...[
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            onPressed: onCancelOccurrence,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: colorScheme.error,
            ),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(24, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            tooltip: 'Cancelar esta sesión',
          ),
        ],
      ],
    );
  }
}

// ── Atom: bottom row with amount + action ─────────────────────────────────────

class _CardBottomRow extends StatelessWidget {
  final Appointment appointment;
  final bool isPaid;
  final bool isSubmitting;
  final Future<void> Function() onPayPressed;

  const _CardBottomRow({
    required this.appointment,
    required this.isPaid,
    required this.isSubmitting,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final pendingAmount = appointment.totalAmount - appointment.amountPaid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 120;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                isPaid
                    ? '\$${appointment.totalAmount}'
                    : '\$$pendingAmount',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: isPaid ? TextDecoration.lineThrough : null,
                  color: isPaid ? colorScheme.outline : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isPaid)
              isNarrow
                  ? _NarrowPayButton(
                      isSubmitting: isSubmitting,
                      onPressed: isSubmitting ? null : onPayPressed,
                    )
                  : ActionButton.tonal(
                      onPressed: isSubmitting ? null : onPayPressed,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            )
                          : const Text(
                              'Cobrar total',
                              style: TextStyle(fontSize: 12),
                            ),
                    )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  'Pagado',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Atom: compact icon-only pay button for narrow cards ─────────────────────

class _NarrowPayButton extends StatelessWidget {
  final bool isSubmitting;
  final Future<void> Function()? onPressed;

  const _NarrowPayButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSubmitting) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.onSecondaryContainer,
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.payments_outlined,
        size: 20,
        color: colorScheme.onSecondaryContainer,
      ),
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: 'Cobrar total',
    );
  }
}

// ── Atom: estimated duration badge ───────────────────────────────────────────

/// Small chip shown on timeline cards when [appointment.endTime] is null
/// and duration is inferred from the provider's default.
class _EstimatedDurationBadge extends StatelessWidget {
  const _EstimatedDurationBadge({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Duration display: we don't know the exact fallback here, so show "estimado"
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        'duración estimada',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 9,
        ),
      ),
    );
  }
}
