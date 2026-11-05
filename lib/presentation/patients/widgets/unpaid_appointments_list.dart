import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cobrador/presentation/shared/modals/danger_confirmation_dialog.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UnpaidAppointmentsList extends ConsumerWidget {
  final String patientId;

  const UnpaidAppointmentsList({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) return const SizedBox.shrink();

    final appointmentsAsync = ref.watch(
      ledgerProvider(providerId: providerId, patientId: patientId),
    );

    return appointmentsAsync.when(
      data: (appointments) => _AppointmentSections(
        appointments: appointments,
        patientId: patientId,
      ),
      loading: () => _LoadingSkeleton(),
      error: (error, _) => Center(
        child: Text(
          'Error al cargar turnos: $error',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
    );
  }
}

// ── Organism: two sections ───────────────────────────────────────────────────

class _AppointmentSections extends StatelessWidget {
  final List<Appointment> appointments;
  final String patientId;

  const _AppointmentSections({
    required this.appointments,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final scheduled = appointments
        .where((a) => a.status == AppointmentStatus.scheduled)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final unpaid = appointments
        .where((a) => a.status == AppointmentStatus.unpaid)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final bothEmpty = scheduled.isEmpty && unpaid.isEmpty;

    if (bothEmpty) {
      return _EmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scheduled.isNotEmpty) ...[
          _ScheduledSection(scheduled: scheduled),
          if (unpaid.isNotEmpty) const SizedBox(height: AppSpacing.lg),
        ],
        _UnpaidSection(unpaid: unpaid),
        const SizedBox(height: AppSpacing.lg),
        const _AppointmentStatusLegend(),
      ],
    );
  }
}

// ── Section: scheduled ───────────────────────────────────────────────────────

class _ScheduledSection extends StatelessWidget {
  final List<Appointment> scheduled;

  const _ScheduledSection({required this.scheduled});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.edgeInsetsH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Turnos agendados',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Se consideran pendiente de pago una vez que la fecha del turno haya pasado.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.edgeInsetsH,
          itemCount: scheduled.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) =>
              _ScheduledAppointmentTile(appointment: scheduled[index]),
        ),
      ],
    );
  }
}

// ── Section: unpaid ──────────────────────────────────────────────────────────

class _UnpaidSection extends StatelessWidget {
  final List<Appointment> unpaid;

  const _UnpaidSection({required this.unpaid});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.edgeInsetsH,
          child: Text(
            'Turnos sin pagar',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (unpaid.isEmpty)
          _EmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: AppSpacing.edgeInsetsH,
            itemCount: unpaid.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _UnpaidAppointmentTile(appointment: unpaid[index]),
          ),
      ],
    );
  }
}

// ── Atom: empty state ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: AppSpacing.edgeInsetsH,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              'No hay turnos pendientes de pago',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Atom: loading skeleton ───────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSpacing.edgeInsetsH,
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => const Card(
          child: ListTile(
            title: Text('Cargando turno...'),
            subtitle: Text('Fecha y hora'),
            trailing: Text('\$ 00,000'),
          ),
        ),
      ),
    );
  }
}

// ── Molecule: scheduled tile ─────────────────────────────────────────────────

class _ScheduledAppointmentTile extends StatelessWidget {
  final Appointment appointment;

  const _ScheduledAppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: () => context.push(
          '/appointments/${appointment.id}',
          extra: appointment,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          appointment.concept.isEmpty ? 'Consulta' : appointment.concept,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(appointment.date),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: _ScheduledTileTrailing(appointment: appointment),
      ),
    );
  }
}

class _ScheduledTileTrailing extends StatelessWidget {
  final Appointment appointment;

  const _ScheduledTileTrailing({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormatter.format(appointment.totalAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.secondary,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Text(
                'Al día',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Consumer(
          builder: (context, ref, _) => IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.secondary),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DangerConfirmationDialog(
        title: 'Cancelar Turno',
        warningText:
            'Al cancelar este turno, se descontará del saldo pendiente del paciente. Si tenía pagos parciales, el dinero será devuelto como saldo a favor o redistribuido a otros pendientes.',
        confirmationWord: 'cancelar',
        confirmButtonText: 'Cancelar turno',
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(
              ledgerProvider(
                providerId: appointment.providerId,
                patientId: appointment.patientId,
              ).notifier,
            )
            .deleteAppointment(appointment.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Turno cancelado con éxito.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}

// ── Molecule: unpaid tile (unchanged) ───────────────────────────────────────

class _UnpaidAppointmentTile extends StatelessWidget {
  final Appointment appointment;

  const _UnpaidAppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: () => context.push(
          '/appointments/${appointment.id}',
          extra: appointment,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          appointment.concept.isEmpty ? 'Consulta' : appointment.concept,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(appointment.date),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(appointment.pendingDebt),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.error,
                  ),
                ),
                if (appointment.amountPaid > 0)
                  Text(
                    'de ${currencyFormatter.format(appointment.totalAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => const DangerConfirmationDialog(
                        title: 'Cancelar Turno',
                        warningText:
                            'Al cancelar este turno, se descontará del saldo pendiente del paciente. Si tenía pagos parciales, el dinero será devuelto como saldo a favor o redistribuido a otros pendientes.',
                        confirmationWord: 'cancelar',
                        confirmButtonText: 'Cancelar turno',
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await ref
                            .read(
                              ledgerProvider(
                                providerId: appointment.providerId,
                                patientId: appointment.patientId,
                              ).notifier,
                            )
                            .deleteAppointment(appointment.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Turno cancelado con éxito.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Atom: status legend ──────────────────────────────────────────────────────

class _AppointmentStatusLegend extends StatelessWidget {
  const _AppointmentStatusLegend();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: AppSpacing.edgeInsetsH,
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          _LegendChip(
            color: colorScheme.secondary,
            label: 'Agendado',
            description: 'aún no tiene saldo pendiente',
            textTheme: textTheme,
          ),
          _LegendChip(
            color: colorScheme.error,
            label: 'Sin pagar',
            description: 'genera saldo pendiente al vencer',
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final String description;
  final TextTheme textTheme;

  const _LegendChip({
    required this.color,
    required this.label,
    required this.description,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label · ',
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          description,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
