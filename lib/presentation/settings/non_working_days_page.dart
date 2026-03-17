import 'package:cobrador/presentation/providers/provider_profile_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/domain/vacation_period.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NonWorkingDaysPage extends ConsumerStatefulWidget {
  const NonWorkingDaysPage({super.key});

  @override
  ConsumerState<NonWorkingDaysPage> createState() => _NonWorkingDaysPageState();
}

class _NonWorkingDaysPageState extends ConsumerState<NonWorkingDaysPage> {
  Future<void> _showAddDayDialog(String providerId) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
      helpText: 'Seleccionar día festivo',
      cancelText: 'Cancelar',
      confirmText: 'Agregar',
    );

    if (pickedDate != null && mounted) {
      final month = pickedDate.month.toString().padLeft(2, '0');
      final day = pickedDate.day.toString().padLeft(2, '0');
      final mmDd = '$month-$day';

      try {
        await ref
            .read(providerProfileProvider(providerId).notifier)
            .addNonWorkingDay(providerId, mmDd);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Día agregado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al agregar día')));
        }
      }
    }
  }

  Future<void> _removeDay(String providerId, String day) async {
    try {
      await ref
          .read(providerProfileProvider(providerId).notifier)
          .removeNonWorkingDay(providerId, day);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Día eliminado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar')));
      }
    }
  }

  Future<void> _showAddVacationDialog(String providerId) async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Seleccionar período de vacaciones',
      cancelText: 'Cancelar',
      confirmText: 'Agregar',
    );

    if (pickedRange != null && mounted) {
      try {
        await ref
            .read(providerProfileProvider(providerId).notifier)
            .addVacationPeriod(providerId, pickedRange.start, pickedRange.end);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vacaciones agregadas correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar vacaciones')),
          );
        }
      }
    }
  }

  Future<void> _removeVacation(String providerId, VacationPeriod period) async {
    try {
      await ref
          .read(providerProfileProvider(providerId).notifier)
          .removeVacationPeriod(providerId, period);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vacaciones eliminadas')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar')));
      }
    }
  }

  String _getHolidayName(String mmDd) {
    switch (mmDd) {
      case '01-01':
        return 'Año Nuevo';
      case '03-24':
        return 'Día de la Memoria';
      case '04-02':
        return 'Día de Malvinas';
      case '05-01':
        return 'Día del Trabajador';
      case '05-25':
        return 'Revolución de Mayo';
      case '06-20':
        return 'Día de la Bandera';
      case '07-09':
        return 'Día de la Independencia';
      case '12-08':
        return 'Inmaculada Concepción';
      case '12-25':
        return 'Navidad';
      default:
        return 'Feriado';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Días no laborables')),
      body: authState.when(
        data: (provider) {
          if (provider == null) {
            return const Center(child: Text('Sesión no encontrada'));
          }

          final profileAsync = ref.watch(providerProfileProvider(provider.id));
          return profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('Perfil no encontrado'));
              }

              final days = profile.nonWorkingDays;
              if (days.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('No hay días registrados.'),
                    ],
                  ),
                );
              }

              // Group days by month
              final Map<int, List<String>> groupedDays = {};
              for (final day in days) {
                final month = int.parse(day.split('-')[0]);
                groupedDays.putIfAbsent(month, () => []).add(day);
              }

              // Sort months and days within months
              final sortedMonths = groupedDays.keys.toList()..sort();
              for (final month in sortedMonths) {
                groupedDays[month]!.sort();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final effectiveMaxWidth =
                      constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
                  final isDesktop = effectiveMaxWidth > 600;
                  final crossAxisCount = isDesktop ? 3 : 2;
                  final spacing = AppSpacing.md;

                  // Calculamos el ancho disponible para cada tarjeta
                  final availableWidth =
                      effectiveMaxWidth - (AppSpacing.md * 2);
                  final itemWidth =
                      (availableWidth - (spacing * (crossAxisCount - 1))) /
                          crossAxisCount -
                      0.1;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        'Los días no laborables evitan la generación automática de turnos. El sistema saltará estas fechas sin cobrarle al paciente.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children:
                                  sortedMonths.map((monthInt) {
                                    final monthDays = groupedDays[monthInt]!;

                                    return SizedBox(
                                      width: itemWidth,
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color:
                                                theme
                                                    .colorScheme
                                                    .outlineVariant,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.md,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize:
                                                MainAxisSize
                                                    .min, // Adapts to content height
                                            children: [
                                              Text(
                                                _getMonthName(monthInt),
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .primary,
                                                    ),
                                              ),
                                              const Divider(height: 24),
                                              Wrap(
                                                spacing: AppSpacing.xs,
                                                runSpacing:
                                                    -8, // Tighter vertical spacing for chips
                                                children:
                                                    monthDays.map((day) {
                                                      final parts = day.split(
                                                        '-',
                                                      );
                                                      final displayDay =
                                                          '${parts[1]}/${parts[0]}';
                                                      final name =
                                                          _getHolidayName(day);

                                                      return Tooltip(
                                                        message: name,
                                                        child: InputChip(
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          label: Text(
                                                            displayDay,
                                                            style:
                                                                theme
                                                                    .textTheme
                                                                    .labelSmall,
                                                          ),
                                                          onDeleted:
                                                              () => _removeDay(
                                                                provider.id,
                                                                day,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // --- Vacations Section ---
                            Text(
                              '🏖️ Modos Vacaciones',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (profile.vacations.isEmpty)
                              const Text(
                                'No hay períodos de vacaciones registrados.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: profile.vacations.length,
                                separatorBuilder:
                                    (_, __) =>
                                        const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final vacation = profile.vacations[index];
                                  final format = DateFormat('dd/MM/yyyy');
                                  final startStr = format.format(
                                    vacation.startDate,
                                  );
                                  final endStr = format.format(
                                    vacation.endDate,
                                  );

                                  return Container(
                                    margin: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primaryContainer
                                              .withOpacity(0.4),
                                          theme.colorScheme.tertiaryContainer
                                              .withOpacity(0.4),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.shadow
                                              .withOpacity(0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.lg,
                                            vertical: AppSpacing.sm,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface
                                              .withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text(
                                          '🌴',
                                          style: TextStyle(fontSize: 24),
                                        ),
                                      ),
                                      title: Text(
                                        '¡Nos fuimos de viaje!',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                            ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_month,
                                              size: 16,
                                              color: theme
                                                  .colorScheme
                                                  .onTertiaryContainer
                                                  .withOpacity(0.8),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                            Text(
                                              '$startStr - $endStr',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onTertiaryContainer,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: theme.colorScheme.error,
                                        ),
                                        onPressed:
                                            () => _removeVacation(
                                              provider.id,
                                              vacation,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error de sesión')),
      ),
      floatingActionButton:
          authState.value != null
              ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'addVacation',
                    onPressed:
                        () => _showAddVacationDialog(authState.value!.id),
                    icon: const Icon(Icons.flight_takeoff),
                    label: const Text('Vacaciones'),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FloatingActionButton.extended(
                    heroTag: 'addHoliday',
                    onPressed: () => _showAddDayDialog(authState.value!.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Feriado'),
                  ),
                ],
              )
              : null,
    );
  }
}
