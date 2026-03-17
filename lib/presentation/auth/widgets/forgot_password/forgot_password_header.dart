import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/auth/widgets/auth_logo.dart';

class ForgotPasswordHeader extends StatelessWidget {
  const ForgotPasswordHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const AuthLogo(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Recuperar contraseña',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Te enviaremos un link para restablecerla',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
