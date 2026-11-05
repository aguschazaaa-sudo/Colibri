import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/create_recurring_appointment_controller.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

class CreateRecurringAppointmentSheet extends ConsumerStatefulWidget {
  final String? initialPatientId;
  final RecurringAppointment? initialRecurringAppointment;

  const CreateRecurringAppointmentSheet({
    super.key,
    this.initialPatientId,
    this.initialRecurringAppointment,
  });

  @override
  ConsumerState<CreateRecurringAppointmentSheet> createState() =>
      _CreateRecurringAppointmentSheetState();
}

class _CreateRecurringAppointmentSheetState
    extends ConsumerState<CreateRecurringAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String _concept = '';
  double _amount = 0.0;
  Frequency _frequency = Frequency.monthly;
  DateTime _baseDate = DateTime.now();
  DateTime? _endDate;
  int? _sessionDurationMinutes;
  late final TextEditingController _conceptController;
  late final TextEditingController _amountController;
  final CurrencyTextInputFormatter _formatter =
      CurrencyTextInputFormatter.currency(
        locale: 'es_AR',
        symbol: '',
        decimalDigits: 0,
      );

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecurringAppointment;
    _selectedPatientId = initial?.patientId ?? widget.initialPatientId;
    _concept = initial?.concept ?? '';
    _amount = initial?.defaultAmount ?? 0.0;
    _frequency = initial?.frequency ?? Frequency.monthly;
    _baseDate = initial?.baseDate ?? DateTime.now();
    _endDate = initial?.endDate;
    _sessionDurationMinutes = initial?.defaultSessionDurationMinutes;

    _conceptController = TextEditingController(text: _concept);
    final amountText = _amount > 0
        ? NumberFormat.decimalPattern('es_AR').format(_amount)
        : (initial != null ? '0' : '');
    _amountController = TextEditingController(text: amountText);
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int _parseAmount(String? value) {
    if (value == null) return 0;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedPatientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente no seleccionado')),
        );
        return;
      }

      final initial = widget.initialRecurringAppointment;
      if (initial == null) {
        await ref
            .read(createRecurringAppointmentControllerProvider.notifier)
            .submit(
              patientId: _selectedPatientId!,
              concept: _concept,
              amount: _amount,
              frequency: _frequency,
              baseDate: _baseDate,
              endDate: _endDate,
              sessionDurationMinutes: _sessionDurationMinutes,
            );
        return;
      }

      await ref
          .read(createRecurringAppointmentControllerProvider.notifier)
          .updateRecurring(
            recurringAppointmentId: initial.id,
            patientId: _selectedPatientId!,
            concept: _concept,
            amount: _amount,
            frequency: _frequency,
            baseDate: _baseDate,
            active: initial.active,
            endDate: _endDate,
            resetSchedule: true,
            sessionDurationMinutes: _sessionDurationMinutes,
          );
    }
  }

  Future<void> _pickBaseDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _baseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_baseDate),
      );
      if (pickedTime != null) {
        setState(() {
          _baseDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _baseDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _baseDate.hour,
            _baseDate.minute,
          );
        });
      }
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _baseDate.add(const Duration(days: 30)),
      firstDate: _baseDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createRecurringAppointmentControllerProvider, (previous, next) {
      if (next is AsyncData && previous is AsyncLoading) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialRecurringAppointment == null
                  ? 'Turno recurrente creado exitosamente'
                  : 'Turno recurrente actualizado',
            ),
          ),
        );
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${next.error}')));
      }
    });

    final insets = MediaQuery.viewInsetsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.initialRecurringAppointment != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: insets.bottom + AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Editar Turno Recurrente' : 'Turno Recurrente',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _RecurringInfoBanner(),
            const SizedBox(height: AppSpacing.md),
            _RecurringPatientDropdown(
              selectedPatientId: _selectedPatientId,
              onChanged: (v) => setState(() => _selectedPatientId = v),
              isEditing: isEditing,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Concepto (e.g. Consulta Ortodoncia)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              controller: _conceptController,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _concept = v ?? '',
            ),
            const SizedBox(height: AppSpacing.md),
            _RecurringAmountAndFrequency(
              amountController: _amountController,
              formatter: _formatter,
              frequency: _frequency,
              onFrequencyChanged: (v) => setState(() => _frequency = v),
              onAmountSaved: (v) => _amount = _parseAmount(v).toDouble(),
              parseAmount: _parseAmount,
            ),
            const SizedBox(height: AppSpacing.md),
            _RecurringDurationField(
              selectedDuration: _sessionDurationMinutes,
              onChanged: (v) => setState(() => _sessionDurationMinutes = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _RecurringDatePickers(
              baseDate: _baseDate,
              endDate: _endDate,
              onPickBaseDate: _pickBaseDate,
              onPickEndDate: _pickEndDate,
              onClearEndDate: () => setState(() => _endDate = null),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Guardar cambios' : 'Crear Recurrencia'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Extracted widgets ────────────────────────────────────────────────────────

/// Info banner explaining how recurring appointments work.
class _RecurringInfoBanner extends StatelessWidget {
  const _RecurringInfoBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Estás creando un turno recurrente.\n'
              'Los turnos se irán generando automáticamente según la '
              'frecuencia elegida, no se crearán todos juntos de una vez.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient dropdown for recurring appointments.
/// When [isEditing] is true the dropdown is disabled (patient cannot change).
class _RecurringPatientDropdown extends ConsumerWidget {
  const _RecurringPatientDropdown({
    required this.selectedPatientId,
    required this.onChanged,
    required this.isEditing,
  });

  final String? selectedPatientId;
  final ValueChanged<String?> onChanged;
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) return const SizedBox.shrink();

    final patientsAsync = ref.watch(patientsProvider(providerId));

    return patientsAsync.when(
      data: (patients) {
        if (patients.isEmpty) {
          return const Text('Agregue un paciente primero');
        }
        return IgnorePointer(
          ignoring: isEditing,
          child: FormField<String>(
            initialValue: selectedPatientId,
            validator: (v) => v == null ? 'Seleccione un paciente' : null,
            builder: (state) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return DropdownMenu<String>(
                    initialSelection: selectedPatientId,
                    width: constraints.maxWidth,
                    menuHeight: 240,
                    label: const Text('Paciente'),
                    leadingIcon: const Icon(Icons.person_outline_rounded),
                    enableFilter: true,
                    enableSearch: true,
                    errorText: state.errorText,
                    dropdownMenuEntries: patients.map((p) {
                      return DropdownMenuEntry(value: p.id, label: p.name);
                    }).toList(),
                    onSelected: (v) {
                      onChanged(v);
                      state.didChange(v);
                    },
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => const Text(
        'No se pudieron cargar los pacientes. Cerrá el formulario e intentá de nuevo.',
      ),
    );
  }
}

/// Row with amount field and frequency dropdown.
class _RecurringAmountAndFrequency extends StatelessWidget {
  const _RecurringAmountAndFrequency({
    required this.amountController,
    required this.formatter,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.onAmountSaved,
    required this.parseAmount,
  });

  final TextEditingController amountController;
  final CurrencyTextInputFormatter formatter;
  final Frequency frequency;
  final ValueChanged<Frequency> onFrequencyChanged;
  final FormFieldSetter<String> onAmountSaved;
  final int Function(String?) parseAmount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Monto recurrente',
              prefixIcon: Icon(Icons.attach_money_rounded),
              helperText: 'Ingresá 0 para sesiones de obra social',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [formatter],
            controller: amountController,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (parseAmount(v) < 0) return 'Monto inválido';
              return null;
            },
            onSaved: onAmountSaved,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DropdownButtonFormField<Frequency>(
            decoration: const InputDecoration(
              labelText: 'Frecuencia',
              prefixIcon: Icon(Icons.refresh_rounded),
            ),
            initialValue: frequency,
            items: const [
              DropdownMenuItem(
                value: Frequency.weekly,
                child: Text('Semanal'),
              ),
              DropdownMenuItem(
                value: Frequency.biweekly,
                child: Text('Quincenal'),
              ),
              DropdownMenuItem(
                value: Frequency.monthly,
                child: Text('Mensual'),
              ),
            ],
            onChanged: (v) {
              if (v != null) onFrequencyChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

/// Duration dropdown for recurring appointments.
/// Null selection means "use provider default at generation time".
class _RecurringDurationField extends StatelessWidget {
  const _RecurringDurationField({
    required this.selectedDuration,
    required this.onChanged,
  });

  final int? selectedDuration;
  final ValueChanged<int?> onChanged;

  static const _options = [15, 30, 45, 50, 60, 75, 90, 120];

  String _fmt(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selectedDuration,
      decoration: const InputDecoration(
        labelText: 'Duración de la sesión',
        prefixIcon: Icon(Icons.timer_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Por defecto del profesional'),
        ),
        ..._options.map(
          (m) => DropdownMenuItem<int?>(value: m, child: Text(_fmt(m))),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Row with start date and end date pickers, plus a "clear end date" button.
class _RecurringDatePickers extends StatelessWidget {
  const _RecurringDatePickers({
    required this.baseDate,
    required this.endDate,
    required this.onPickBaseDate,
    required this.onPickEndDate,
    required this.onClearEndDate,
  });

  final DateTime baseDate;
  final DateTime? endDate;
  final VoidCallback onPickBaseDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearEndDate;

  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickBaseDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(
                  'Inicio:\n${_dateTimeFormat.format(baseDate)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickEndDate,
                icon: const Icon(Icons.event_busy_rounded, size: 18),
                label: Text(
                  endDate == null
                      ? 'Sin fin\n(Opcional)'
                      : 'Fin:\n${_dateFormat.format(endDate!)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        if (endDate != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClearEndDate,
              child: const Text('Quitar fecha de fin'),
            ),
          ),
      ],
    );
  }
}
