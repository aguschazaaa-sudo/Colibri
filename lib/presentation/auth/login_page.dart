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
import 'package:cobrador/presentation/auth/widgets/login/login_header.dart';
import 'package:cobrador/presentation/auth/widgets/login/login_form.dart';
import 'package:cobrador/presentation/auth/widgets/login/login_button.dart';
import 'package:cobrador/presentation/auth/widgets/login/login_links.dart';

/// Login page — email/password + Google sign-in.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return AuthBackground(
      child: AuthCard(
        children: [
          const LoginHeader(),
          const SizedBox(height: AppSpacing.lg),
          LoginForm(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            onToggleObscure:
                () => setState(() => _obscurePassword = !_obscurePassword),
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.sm),
          const ForgotPasswordLink(),
          const SizedBox(height: AppSpacing.md),
          LoginButton(isLoading: isLoading, onPressed: _handleLogin),
          const OrDivider(),
          SocialSignInButton(
            isLoading: isLoading,
            onPressed: _handleGoogleSignIn,
          ),
          const SizedBox(height: AppSpacing.lg),
          const RegisterLink(),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref
        .read(authNotifierProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    result.fold(
      (failure) => _showError(failure),
      (_) {}, // GoRouter redirect handles navigation
    );
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
      invalidCredentials: () => 'Email o contraseña incorrectos.',
      weakPassword: () => 'La contraseña es muy débil.',
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
