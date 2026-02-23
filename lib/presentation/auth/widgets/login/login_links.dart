import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => context.go('/forgot-password'),
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(color: colorScheme.primary),
        ),
      ),
    );
  }
}

class RegisterLink extends StatelessWidget {
  const RegisterLink({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿No tenés cuenta? ', style: textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(
            'Registrate',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
