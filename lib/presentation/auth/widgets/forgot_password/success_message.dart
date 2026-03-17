import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

class SuccessMessage extends StatelessWidget {
  const SuccessMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '¡Email enviado!',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Revisá tu bandeja de entrada o la carpeta de **Spam** y seguí las instrucciones para restablecer tu contraseña.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onTertiaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
