import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Styled button for Google sign-in.
///
/// Shows the Google logo (via Material icon) with themed styling.
class SocialSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" icon using a simple text approach
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Continuar con Google',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
