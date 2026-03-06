import 'package:cobrador/presentation/providers/provider_profile_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  final isDesktop = constraints.maxWidth > 900;
                  final crossAxisCount = isDesktop ? 3 : 2;
                  final spacing = AppSpacing.md;

                  // Calculamos el ancho disponible para cada tarjeta
                  final availableWidth =
                      constraints.maxWidth - (AppSpacing.md * 2);
                  final itemWidth =
                      (availableWidth - (spacing * (crossAxisCount - 1))) /
                          crossAxisCount -
                      0.1;

                  return SingleChildScrollView(
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
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
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
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
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                          const Divider(height: 24),
                                          Wrap(
                                            spacing: AppSpacing.xs,
                                            runSpacing:
                                                -8, // Tighter vertical spacing for chips
                                            children:
                                                monthDays.map((day) {
                                                  final parts = day.split('-');
                                                  final displayDay =
                                                      '${parts[1]}/${parts[0]}';
                                                  final name = _getHolidayName(
                                                    day,
                                                  );

                                                  return Tooltip(
                                                    message: name,
                                                    child: InputChip(
                                                      visualDensity:
                                                          VisualDensity.compact,
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
                      ],
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
              ? FloatingActionButton.extended(
                onPressed: () => _showAddDayDialog(authState.value!.id),
                icon: const Icon(Icons.add),
                label: const Text('Añadir Día'),
              )
              : null,
    );
  }
}
