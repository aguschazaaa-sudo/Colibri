import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
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
          date: DateTime.now(), // By default creating it for today
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
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
              onSaved: (v) => _amount = double.tryParse(v ?? '') ?? 0.0,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Agendar y Generar Deuda'),
            ),
          ],
        ),
      ),
    );
  }
}
