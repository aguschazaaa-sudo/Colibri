import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/create_recurring_appointment_controller.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final isLoading =
        ref.read(createRecurringAppointmentControllerProvider).isLoading;
    if (isLoading) return;

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
    final date = await showDatePicker(
      context: context,
      initialDate: _baseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _baseDate = date);
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
    final _isSubmitting = controllerState.isLoading;

    final insets = MediaQuery.viewInsetsOf(context);
    final textTheme = Theme.of(context).textTheme;

    final dateFormat = DateFormat('dd/MM/yyyy');

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
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Paciente',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      value: _selectedPatientId,
                      items:
                          patients.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            );
                          }).toList(),
                      onChanged: (v) => setState(() => _selectedPatientId = v),
                      validator:
                          (v) => v == null ? 'Seleccione un paciente' : null,
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
                          : 'Fin:\n${dateFormat.format(_endDate!)}',
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
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Crear Recurrencia'),
            ),
          ],
        ),
      ),
    );
  }
}
