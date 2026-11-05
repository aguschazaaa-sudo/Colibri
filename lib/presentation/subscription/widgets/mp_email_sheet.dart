import 'package:flutter/material.dart';

/// Bottom sheet that optionally asks the user for their MercadoPago email.
///
/// Returns:
/// - `null` if the user dismissed the sheet (cancel)
/// - `''` if the user pressed "Continuar" without entering an email (use Auth email)
/// - A non-empty string with the MP email to use
class MpEmailSheet extends StatefulWidget {
  const MpEmailSheet({super.key});

  @override
  State<MpEmailSheet> createState() => _MpEmailSheetState();
}

class _MpEmailSheetState extends State<MpEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email de MercadoPago',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Si tu cuenta de MercadoPago usa un email distinto al de tu '
              'cuenta en ColibriMD, ingresalo acá para evitar problemas con '
              'el pago.\n\nSi es el mismo, dejalo vacío.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email de MercadoPago (opcional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingresá un email válido';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
