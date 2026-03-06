import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/shared/modals/create_recurring_appointment_sheet.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RecurringAppointmentsList extends ConsumerWidget {
  final String patientId;

  const RecurringAppointmentsList({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) return const SizedBox.shrink();

    final appointmentsAsync = ref.watch(
      patientRecurringAppointmentsProvider(
        providerId: providerId,
        patientId: patientId,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.edgeInsetsH,
          child: Text(
            'Turnos recurrentes',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        appointmentsAsync.when(
          data: (appointments) {
            final now = DateTime.now();
            final active =
                appointments
                    .where((a) => a.endDate == null || a.endDate!.isAfter(now))
                    .toList()
                  ..sort((a, b) => a.baseDate.compareTo(b.baseDate));

            if (active.isEmpty) {
              return Padding(
                padding: AppSpacing.edgeInsetsH,
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'No hay turnos recurrentes activos',
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
              itemCount: active.length,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return _RecurringAppointmentTile(appointment: active[index]);
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
                        subtitle: Text('Frecuencia y monto'),
                        trailing: Icon(Icons.edit),
                      ),
                    );
                  },
                ),
              ),
          error:
              (error, _) => Center(
                child: Text(
                  'Error al cargar turnos recurrentes: $error',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
        ),
      ],
    );
  }
}

class _RecurringAppointmentTile extends StatelessWidget {
  final RecurringAppointment appointment;

  const _RecurringAppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$',
      decimalDigits: 0,
    );
    final colorScheme = Theme.of(context).colorScheme;

    String frequencyText;
    switch (appointment.frequency) {
      case Frequency.weekly:
        frequencyText = 'Semanal';
        break;
      case Frequency.biweekly:
        frequencyText = 'Quincenal';
        break;
      case Frequency.monthly:
        frequencyText = 'Mensual';
        break;
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
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
          '$frequencyText - ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.baseDate)}',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormatter.format(appointment.defaultAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder:
                      (_) => CreateRecurringAppointmentSheet(
                        initialPatientId: appointment.patientId,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
