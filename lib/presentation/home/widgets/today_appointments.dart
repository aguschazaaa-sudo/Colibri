import 'package:cobrador/presentation/home/widgets/atoms/appointments_empty_state.dart';
import 'package:cobrador/presentation/home/widgets/day_timeline_view.dart';
import 'package:cobrador/presentation/providers/day_schedule_provider.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Section widget that owns the selected-date state and renders the
/// [DayTimelineView] for the chosen day.
///
/// Height is controlled by the parent — this widget expands to fill whatever
/// space its ancestor provides (use [Expanded] or [Flexible] above it).
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
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid ?? '';

    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final dateString =
        isToday ? 'Hoy' : DateFormat('E d MMM', 'es').format(_selectedDate);

    final scheduleAsync = ref.watch(
      dayScheduleProvider(providerId: providerId, date: _selectedDate),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateNavigationRow(
          dateString: dateString,
          onPrevious: () => setState(
            () =>
                _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
          ),
          onNext: () => setState(
            () => _selectedDate = _selectedDate.add(const Duration(days: 1)),
          ),
          onCalendarTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: scheduleAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const AppointmentsEmptyState();
              }
              return DayTimelineView(
                items: items,
                selectedDate: _selectedDate,
                isToday: isToday,
                providerId: providerId,
              );
            },
            loading: () => const DayTimelineSkeleton(),
            error: (err, stack) => _AppointmentsErrorState(
              onRetry: () => ref.invalidate(
                dayScheduleProvider(providerId: providerId, date: _selectedDate),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Molecule: date navigation header ─────────────────────────────────────────

class _DateNavigationRow extends StatelessWidget {
  final String dateString;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCalendarTap;

  const _DateNavigationRow({
    required this.dateString,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: AppSpacing.edgeInsetsH,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(
            dateString.toUpperCase(),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: colorScheme.primary,
              size: 20,
            ),
            onPressed: onCalendarTap,
          ),
        ],
      ),
    );
  }
}

// ── Molecule: error state with retry ─────────────────────────────────────────

class _AppointmentsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _AppointmentsErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Error cargando turnos',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
