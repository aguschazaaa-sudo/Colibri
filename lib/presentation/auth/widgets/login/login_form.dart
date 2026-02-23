import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresá tu email';
              }
              if (!value.contains('@')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresá tu contraseña';
              }
              if (value.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
