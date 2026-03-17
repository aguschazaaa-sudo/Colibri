import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

/// Shows the [EditPatientModal] as a bottom sheet.
Future<void> showEditPatientModal(
  BuildContext context,
  WidgetRef ref,
  Patient patient,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => EditPatientModal(parentRef: ref, patient: patient),
  );
}

/// Bottom sheet form for editing an existing patient.
class EditPatientModal extends ConsumerStatefulWidget {
  /// The [WidgetRef] from the calling page, used to access [patientsProvider].
  final WidgetRef parentRef;

  /// The patient being edited
  final Patient patient;

  const EditPatientModal({
    super.key,
    required this.parentRef,
    required this.patient,
  });

  @override
  ConsumerState<EditPatientModal> createState() => _EditPatientModalState();
}

class _EditPatientModalState extends ConsumerState<EditPatientModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _phoneController = TextEditingController(text: widget.patient.phoneNumber);
    _emailController = TextEditingController(text: widget.patient.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = widget.parentRef.read(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;
    if (providerId == null) return;

    try {
      final updatedPatient = widget.patient.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
      );

      await widget.parentRef
          .read(patientsProvider(providerId).notifier)
          .updatePatient(updatedPatient);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente actualizado con éxito'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Editar Paciente',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'El nombre es obligatorio'
                          : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono / WhatsApp *',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'El teléfono es obligatorio'
                          : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.lg),
            ActionButton(
              onPressed: _submit,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded),
                  SizedBox(width: AppSpacing.sm),
                  Text('Guardar Cambios'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
