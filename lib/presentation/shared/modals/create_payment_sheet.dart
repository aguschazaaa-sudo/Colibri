import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';

class CreatePaymentSheet extends ConsumerStatefulWidget {
  final String? initialPatientId;

  const CreatePaymentSheet({super.key, this.initialPatientId});

  @override
  ConsumerState<CreatePaymentSheet> createState() => _CreatePaymentSheetState();
}

class _CreatePaymentSheetState extends ConsumerState<CreatePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  double _amount = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate() && _selectedPatientId != null) {
      setState(() => _isSubmitting = true);
      _formKey.currentState!.save();

      try {
        final auth = ref.read(firebaseAuthProvider);
        final providerId = auth.currentUser?.uid ?? '';

        // Create the Domain Payment object
        final payment = Payment(
          id: '', // Empty or generate UUID, let backend assign real ID
          patientId: _selectedPatientId!,
          providerId: providerId,
          amount: _amount,
          date: DateTime.now(),
        );

        // Access the Ledger provider logic
        // We use ref.read within callbacks according to Riverpod rules
        await ref
            .read(
              ledgerProvider(
                providerId: providerId,
                patientId: _selectedPatientId!,
              ).notifier,
            )
            .registerPayment(payment);

        if (mounted) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago registrado y distribuido.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error guardando el pago: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
            Text('Añadir Pago', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final auth = ref.watch(firebaseAuthProvider);
                final providerId = auth.currentUser?.uid ?? '';

                return ref
                    .watch(patientsProvider(providerId))
                    .when(
                      data: (patients) {
                        if (patients.isEmpty) {
                          return const Text(
                            'Primero debes registrar un paciente.',
                            style: TextStyle(color: Colors.red),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Paciente',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          items:
                              patients
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                        '${p.name} (Deuda: \$${p.totalDebt.toStringAsFixed(0)})',
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedPatientId = v),
                          validator:
                              (v) =>
                                  v == null ? 'Seleccione un paciente' : null,
                        );
                      },
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monto recibido',
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
              onPressed: _isSubmitting ? null : _submit,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Registrar Pago'),
            ),
          ],
        ),
      ),
    );
  }
}
