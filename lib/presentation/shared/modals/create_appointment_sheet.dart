import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CreateAppointmentSheet extends ConsumerStatefulWidget {
  final String? initialPatientId;

  const CreateAppointmentSheet({super.key, this.initialPatientId});

  @override
  ConsumerState<CreateAppointmentSheet> createState() =>
      _CreateAppointmentSheetState();
}

class _CreateAppointmentSheetState
    extends ConsumerState<CreateAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String _concept = '';
  double _amount = 0.0;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      _formKey.currentState!.save();

      try {
        final auth = ref.read(firebaseAuthProvider);
        final providerId = auth.currentUser?.uid;
        if (providerId == null) throw Exception('No user logged in');

        if (_selectedPatientId == null) {
          throw Exception('Paciente no seleccionado');
        }

        final newAppointment = Appointment(
          id: '', // Auto-generated
          patientId: _selectedPatientId!,
          providerId: providerId,
          date: _selectedDate,
          concept: _concept,
          totalAmount: _amount,
          amountPaid: 0.0,
          status: AppointmentStatus.unpaid,
        );

        await ref
            .read(
              ledgerProvider(
                providerId: providerId,
                patientId: _selectedPatientId!,
              ).notifier,
            )
            .createAppointment(newAppointment);

        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Turno agendado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final textTheme = Theme.of(context).textTheme;

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
            Text('Agendar Turno', style: textTheme.titleLarge),
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
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha del Turno',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Concepto (e.g. Consulta general)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _concept = v ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monto a cobrar',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_formatter],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (_formatter.getUnformattedValue() <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
              onSaved:
                  (v) => _amount = _formatter.getUnformattedValue().toDouble(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Agendar y Generar Deuda'),
            ),
          ],
        ),
      ),
    );
  }
}
