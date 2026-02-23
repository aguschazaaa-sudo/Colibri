import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';

class TodayAppointmentsSection extends ConsumerWidget {
  const TodayAppointmentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // We'll watch all appointments. Since we don't have a specific 'today' provider yet,
    // we fetch them and filter them client side, or rely on a future specific provider.
    final appointmentsAsync = ref.watch(
      ledgerProvider(providerId: 'prov_1', patientId: ''),
    );

    return appointmentsAsync.when(
      data: (appointments) {
        // Here we would ideally filter by today. For the UI mockup we just show all unpaid
        final todayAppointments =
            appointments
                .where((a) => a.status == AppointmentStatus.unpaid)
                .toList();

        if (todayAppointments.isEmpty) {
          return _EmptyState(textTheme: textTheme, colorScheme: colorScheme);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.edgeInsetsH,
              child: Text(
                'Turnos pendientes',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 140, // Height for the horizontal list
              child: ListView.separated(
                padding: AppSpacing.edgeInsetsH,
                scrollDirection: Axis.horizontal,
                itemCount: todayAppointments.length,
                separatorBuilder:
                    (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final apt = todayAppointments[index];
                  return _AppointmentCard(appointment: apt);
                },
              ),
            ),
          ],
        );
      },
      loading:
          () => Skeletonizer(
            enabled: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppSpacing.edgeInsetsH,
                  child: Text(
                    'Turnos pendientes',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    padding: AppSpacing.edgeInsetsH,
                    scrollDirection: Axis.horizontal,
                    itemCount: 3, // Generate 3 dummy cards
                    separatorBuilder:
                        (_, __) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _AppointmentCard(
                        appointment: Appointment(
                          id: '',
                          patientId: 'Cargando nombre largo asd...',
                          providerId: '',
                          date: DateTime.now(),
                          concept: 'Consulta general',
                          totalAmount: 90000,
                          amountPaid: 0,
                          status: AppointmentStatus.unpaid,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      error:
          (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Error cargando turnos',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _EmptyState({required this.textTheme, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No hay turnos agendados para hoy',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final Appointment appointment; // Now receiving the whole domain entity

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isPaid = appointment.status == AppointmentStatus.liquidated;
    final time =
        '${appointment.date.hour.toString().padLeft(2, '0')}:${appointment.date.minute.toString().padLeft(2, '0')}';

    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              if (!isPaid)
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colorScheme.error,
                )
              else
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Colors.green.shade600,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            appointment
                .patientId, // In the real app, we use PatientProvider to read Name
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            appointment.concept,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${appointment.totalAmount - appointment.amountPaid}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isPaid)
                FilledButton.tonal(
                  onPressed: () async {
                    try {
                      final payment = Payment(
                        id: '',
                        patientId: appointment.patientId,
                        providerId: appointment.providerId,
                        amount:
                            appointment.totalAmount -
                            appointment.amountPaid, // Full pay by default here
                        date: DateTime.now(),
                        appointmentId: appointment.id,
                      );
                      // Quick action triggers optimistic UI calculation instantly
                      await ref
                          .read(
                            ledgerProvider(
                              providerId: appointment.providerId,
                              patientId: appointment.patientId,
                            ).notifier,
                          )
                          .registerPayment(payment);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pago registrado')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Cobrar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
