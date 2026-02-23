import 'package:flutter/material.dart';

class EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;

  const EmailForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: emailController,
        enabled: !isLoading,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ingresá tu email';
          }
          if (!value.contains('@')) return 'Email inválido';
          return null;
        },
      ),
    );
  }
}
