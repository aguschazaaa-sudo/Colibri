import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/create_recurring_appointment_controller.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

class CreateRecurringAppointmentSheet extends ConsumerStatefulWidget {
  final String? initialPatientId;

  const CreateRecurringAppointmentSheet({super.key, this.initialPatientId});

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
  final CurrencyTextInputFormatter _formatter =
      CurrencyTextInputFormatter.currency(
        locale: 'es_AR',
        symbol: '',
        decimalDigits: 0,
      );

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
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

      await ref
          .read(createRecurringAppointmentControllerProvider.notifier)
          .submit(
            patientId: _selectedPatientId!,
            concept: _concept,
            amount: _amount,
            frequency: _frequency,
            baseDate: _baseDate,
            endDate: _endDate,
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
    // Listen for submission state changes
    ref.listen(createRecurringAppointmentControllerProvider, (previous, next) {
      if (next is AsyncData && previous is AsyncLoading) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abono recurrente creado exitosamente')),
        );
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${next.error}')));
      }
    });

    final controllerState = ref.watch(
      createRecurringAppointmentControllerProvider,
    );

    final insets = MediaQuery.viewInsetsOf(context);
    final textTheme = Theme.of(context).textTheme;

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final endDateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: insets.bottom + 16,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Turno Recurrente', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estás creando una regla de facturación.\nLos turnos se irán generando automáticamente según la frecuencia elegida, no se crearán todos juntos de una vez.',
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final auth = ref.watch(firebaseAuthProvider);
                final providerId = auth.currentUser?.uid;

                if (providerId == null) return const SizedBox.shrink();

                final patientsAsync = ref.watch(patientsProvider(providerId));

                return patientsAsync.when(
                  data: (patients) {
                    if (patients.isEmpty) {
                      return const Text('Agregue un paciente primero');
                    }
                    return FormField<String>(
                      initialValue: _selectedPatientId,
                      validator:
                          (v) => v == null ? 'Seleccione un paciente' : null,
                      builder: (state) {
                        return DropdownMenu<String>(
                          initialSelection: _selectedPatientId,
                          expandedInsets: EdgeInsets.zero,
                          label: const Text('Paciente'),
                          leadingIcon: const Icon(Icons.person_outline_rounded),
                          enableFilter: true,
                          enableSearch: true,
                          errorText: state.errorText,
                          dropdownMenuEntries:
                              patients.map((p) {
                                return DropdownMenuEntry(
                                  value: p.id,
                                  label: p.name,
                                );
                              }).toList(),
                          onSelected: (v) {
                            setState(() => _selectedPatientId = v);
                            state.didChange(v);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Error al cargar pacientes: $e'),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Concepto (e.g. Abono Ortodoncia)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _concept = v ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Monto recurrente',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_formatter],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (_formatter.getUnformattedValue() <= 0) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                    onSaved:
                        (v) =>
                            _amount =
                                _formatter.getUnformattedValue().toDouble(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Frequency>(
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia',
                      prefixIcon: Icon(Icons.refresh_rounded),
                    ),
                    value: _frequency,
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
                      if (v != null) {
                        setState(() => _frequency = v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickBaseDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      'Inicio:\n${dateFormat.format(_baseDate)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event_busy_rounded, size: 18),
                    label: Text(
                      _endDate == null
                          ? 'Sin fin\n(Opcional)'
                          : 'Fin:\n${endDateFormat.format(_endDate!)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            if (_endDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: const Text('Quitar fecha de fin'),
                ),
              )
            else
              const SizedBox(height: 16),
            const SizedBox(height: 8),
            ActionButton(
              onPressed: _submit,
              child: const Text('Crear Recurrencia'),
            ),
          ],
        ),
      ),
    );
  }
}
