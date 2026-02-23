import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/presentation/auth/widgets/auth_background.dart';
import 'package:cobrador/presentation/auth/widgets/auth_card.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

// Extracted widgets
import 'package:cobrador/presentation/auth/widgets/forgot_password/forgot_password_header.dart';
import 'package:cobrador/presentation/auth/widgets/forgot_password/email_form.dart';
import 'package:cobrador/presentation/auth/widgets/forgot_password/send_button.dart';
import 'package:cobrador/presentation/auth/widgets/forgot_password/success_message.dart';
import 'package:cobrador/presentation/auth/widgets/forgot_password/back_to_login_link.dart';

/// Forgot password page — enter email to receive reset link.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return AuthBackground(
      child: AuthCard(
        children: [
          const ForgotPasswordHeader(),
          const SizedBox(height: AppSpacing.lg),
          if (_emailSent)
            const SuccessMessage()
          else ...[
            EmailForm(
              formKey: _formKey,
              emailController: _emailController,
              isLoading: isLoading,
            ),
            const SizedBox(height: AppSpacing.lg),
            SendButton(isLoading: isLoading, onPressed: _handleResetPassword),
          ],
          const SizedBox(height: AppSpacing.lg),
          const BackToLoginLink(),
        ],
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(_emailController.text.trim());
    if (!mounted) return;
    result.fold(
      (failure) => _showError(failure),
      (_) => setState(() => _emailSent = true),
    );
  }

  void _showError(Failure failure) {
    final message = failure.when(
      serverError: (msg) => msg,
      validationError: (msg) => msg,
      unauthorized: (msg) => msg,
      notFound: (msg) => 'No se encontró una cuenta con ese email.',
      unknown: (msg) => msg,
      emailAlreadyInUse: () => 'Error inesperado.',
      invalidCredentials: () => 'Error inesperado.',
      weakPassword: () => 'Error inesperado.',
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
