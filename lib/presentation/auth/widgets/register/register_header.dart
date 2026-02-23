import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.hive_rounded, size: 48, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Creá tu cuenta',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Empezá a gestionar tus cobros hoy',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
