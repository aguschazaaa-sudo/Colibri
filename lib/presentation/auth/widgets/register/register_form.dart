import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresá tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
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
              if (!value.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresá una contraseña';
              }
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: confirmPasswordController,
            enabled: !isLoading,
            obscureText: obscureConfirm,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleConfirm,
              ),
            ),
            validator: (value) {
              if (value != passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
