import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

class TodayAppointmentsSection extends ConsumerStatefulWidget {
  const TodayAppointmentsSection({super.key});

  @override
  ConsumerState<TodayAppointmentsSection> createState() =>
      _TodayAppointmentsSectionState();
}

class _TodayAppointmentsSectionState
    extends ConsumerState<TodayAppointmentsSection> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid ?? '';

    final appointmentsAsync = ref.watch(
      ledgerProvider(providerId: providerId, patientId: ''),
    );

    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dateString =
        isToday ? 'Hoy' : DateFormat('E d MMM', 'es').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.edgeInsetsH,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
              ),
              Text(
                dateString.toUpperCase(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 140, // Height for the horizontal list
          child: appointmentsAsync.when(
            data: (appointments) {
              final dailyAppointments =
                  appointments
                      .where(
                        (a) =>
                            a.date.year == _selectedDate.year &&
                            a.date.month == _selectedDate.month &&
                            a.date.day == _selectedDate.day,
                      )
                      .toList()
                    ..sort((a, b) => a.date.compareTo(b.date));

              if (dailyAppointments.isEmpty) {
                return _EmptyState(
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                );
              }

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.separated(
                  padding: AppSpacing.edgeInsetsH,
                  scrollDirection: Axis.horizontal,
                  itemCount: dailyAppointments.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final apt = dailyAppointments[index];
                    return _AppointmentCard(appointment: apt)
                        .animate(delay: (100 * index).ms)
                        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                        .slideX(
                          begin: 0.05,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        );
                  },
                ),
              );
            },
            loading:
                () => Skeletonizer(
                  enabled: true,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
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
                ),
            error:
                (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colorScheme.error,
                        ),
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
          ),
        ),
      ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No hay turnos para esta fecha', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerStatefulWidget {
  final Appointment appointment; // Now receiving the whole domain entity

  const _AppointmentCard({required this.appointment});

  @override
  ConsumerState<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends ConsumerState<_AppointmentCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appointment = widget.appointment;

    final isSkeleton = appointment.providerId.isEmpty;
    final patientsAsync =
        isSkeleton ? null : ref.watch(patientsProvider(appointment.providerId));

    final patientName =
        isSkeleton
            ? appointment.patientId
            : (patientsAsync?.valueOrNull
                    ?.where((p) => p.id == appointment.patientId)
                    .firstOrNull
                    ?.name ??
                'Cargando...');

    final isPaid = appointment.status == AppointmentStatus.liquidated;
    final time =
        '${appointment.date.hour.toString().padLeft(2, '0')}:${appointment.date.minute.toString().padLeft(2, '0')}';

    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isPaid
                ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: isPaid ? Colors.transparent : colorScheme.outlineVariant,
        ),
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
                  color: isPaid ? colorScheme.outline : colorScheme.primary,
                  decoration: isPaid ? TextDecoration.lineThrough : null,
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
            patientName,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  isPaid ? colorScheme.onSurfaceVariant.withOpacity(0.6) : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            appointment.concept,
            style: textTheme.bodySmall?.copyWith(
              color:
                  isPaid ? colorScheme.outline : colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPaid
                    ? '\$${appointment.totalAmount}'
                    : '\$${appointment.totalAmount - appointment.amountPaid}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: isPaid ? TextDecoration.lineThrough : null,
                  color: isPaid ? colorScheme.outline : null,
                ),
              ),
              if (!isPaid)
                ActionButton.tonal(
                  onPressed:
                      _isSubmitting
                          ? null
                          : () async {
                            if (_isSubmitting) return;
                            setState(() => _isSubmitting = true);
                            try {
                              final payment = Payment(
                                id: '',
                                patientId: appointment.patientId,
                                providerId: appointment.providerId,
                                amount:
                                    appointment.totalAmount -
                                    appointment.amountPaid,
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

                              if (context.mounted) {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pago registrado'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
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
                  child: const Text(
                    'Cobrar total',
                    style: TextStyle(fontSize: 12),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
          ),
        ],
      ),
    );
  }
}
