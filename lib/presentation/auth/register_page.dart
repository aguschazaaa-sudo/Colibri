import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/presentation/auth/widgets/auth_background.dart';
import 'package:cobrador/presentation/auth/widgets/auth_card.dart';
import 'package:cobrador/presentation/auth/widgets/social_sign_in_button.dart';
import 'package:cobrador/presentation/auth/widgets/or_divider.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

// Extracted widgets
import 'package:cobrador/presentation/auth/widgets/register/register_header.dart';
import 'package:cobrador/presentation/auth/widgets/register/register_form.dart';
import 'package:cobrador/presentation/auth/widgets/register/register_button.dart';
import 'package:cobrador/presentation/auth/widgets/register/login_link.dart';

/// Registration page — name, email, password, confirm password.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return AuthBackground(
      child: AuthCard(
        children: [
          const RegisterHeader(),
          const SizedBox(height: AppSpacing.lg),
          RegisterForm(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            obscurePassword: _obscurePassword,
            obscureConfirm: _obscureConfirm,
            onTogglePassword:
                () => setState(() => _obscurePassword = !_obscurePassword),
            onToggleConfirm:
                () => setState(() => _obscureConfirm = !_obscureConfirm),
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.lg),
          RegisterButton(isLoading: isLoading, onPressed: _handleRegister),
          const OrDivider(),
          SocialSignInButton(
            isLoading: isLoading,
            onPressed: _handleGoogleSignIn,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LoginLink(),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref
        .read(authNotifierProvider.notifier)
        .register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
    if (!mounted) return;
    result.fold((failure) => _showError(failure), (_) {});
  }

  Future<void> _handleGoogleSignIn() async {
    final result = await ref.read(authNotifierProvider.notifier).googleSignIn();
    if (!mounted) return;
    result.fold((failure) => _showError(failure), (_) {});
  }

  void _showError(Failure failure) {
    final message = failure.when(
      serverError: (msg) => msg,
      validationError: (msg) => msg,
      unauthorized: (msg) => msg,
      notFound: (msg) => msg,
      unknown: (msg) => msg,
      emailAlreadyInUse: () => 'Este email ya está registrado.',
      invalidCredentials: () => 'Credenciales inválidas.',
      weakPassword:
          () => 'La contraseña es muy débil. Usá al menos 6 caracteres.',
      networkError: () => 'Sin conexión a internet.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
