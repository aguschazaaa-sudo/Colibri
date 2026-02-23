import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginLink extends StatelessWidget {
  const LoginLink({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿Ya tenés cuenta? ', style: textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'Iniciá sesión',
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
