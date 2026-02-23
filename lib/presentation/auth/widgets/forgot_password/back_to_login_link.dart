import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackToLoginLink extends StatelessWidget {
  const BackToLoginLink({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: TextButton.icon(
        onPressed: () => context.go('/login'),
        icon: Icon(Icons.arrow_back, size: 18, color: colorScheme.primary),
        label: Text(
          'Volver al login',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
