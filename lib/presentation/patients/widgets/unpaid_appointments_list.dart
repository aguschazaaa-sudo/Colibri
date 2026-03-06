import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) return const SizedBox.shrink();

    final appointmentsAsync = ref.watch(
      ledgerProvider(providerId: providerId, patientId: patientId),
    );

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
        appointmentsAsync.when(
          data: (appointments) {
            final unpaid =
                appointments
                    .where((a) => a.status == AppointmentStatus.unpaid)
                    .toList()
                  ..sort((a, b) => a.date.compareTo(b.date));

            if (unpaid.isEmpty) {
              return Padding(
                padding: AppSpacing.edgeInsetsH,
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: AppSpacing.edgeInsetsH,
              itemCount: unpaid.length,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return _UnpaidAppointmentTile(appointment: unpaid[index]);
              },
            );
          },
          loading:
              () => Skeletonizer(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: AppSpacing.edgeInsetsH,
                  itemCount: 2,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return const Card(
                      child: ListTile(
                        title: Text('Cargando turno...'),
                        subtitle: Text('Fecha y hora'),
                        trailing: Text('\$ 00,000'),
                      ),
                    );
                  },
                ),
              ),
          error:
              (error, _) => Center(
                child: Text(
                  'Error al cargar turnos: $error',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
        ),
      ],
    );
  }
}

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
      color: colorScheme.errorContainer.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.error.withOpacity(0.2)),
      ),
      child: ListTile(
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
                      builder:
                          (context) => DangerConfirmationDialog(
                            title: 'Cancelar Turno',
                            warningText:
                                'Al cancelar este turno, se descontará de la deuda del paciente. Si tenía pagos parciales, el dinero será devuelto como saldo a favor o redistribuido a otras deudas.',
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
