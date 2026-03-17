import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Simple footer with copyright and legal links.
class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.horizontalPadding(
        context,
      ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withAlpha(60)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(
                label: 'Términos',
                onTap: () => context.push('/terms'),
              ),
              const SizedBox(width: AppSpacing.lg),
              _FooterLink(
                label: 'Privacidad',
                onTap: () => context.push('/privacy'),
              ),
              const SizedBox(width: AppSpacing.lg),
              _FooterLink(label: 'Contacto', onTap: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '© 2026 Colibrí. Todos los derechos reservados.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
