import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

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
  late final String _idempotencyKey;
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
    _idempotencyKey = const Uuid().v4();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate() && _selectedPatientId != null) {
      _formKey.currentState!.save();
      setState(() => _isSubmitting = true);

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
          idempotencyKey: _idempotencyKey,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error guardando el pago: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
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
                        return FormField<String>(
                          initialValue: _selectedPatientId,
                          validator:
                              (v) =>
                                  v == null ? 'Seleccione un paciente' : null,
                          builder: (state) {
                            return DropdownMenu<String>(
                              initialSelection: _selectedPatientId,
                              expandedInsets: EdgeInsets.zero,
                              label: const Text('Paciente'),
                              leadingIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              enableFilter: true,
                              enableSearch: true,
                              errorText: state.errorText,
                              dropdownMenuEntries:
                                  patients.map((p) {
                                    return DropdownMenuEntry(
                                      value: p.id,
                                      label:
                                          '${p.name} (Deuda: \$${p.totalDebt.toStringAsFixed(0)})',
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
            ActionButton(
              onPressed: _submit,
              child: const Text('Registrar Pago'),
            ),
          ],
        ),
      ),
    );
  }
}
