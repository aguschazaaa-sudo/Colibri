import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

/// Final call-to-action block with a provocative phrase and big CTA button.
class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withAlpha(220)],
        ),
      ),
      child: Padding(
        padding: AppSpacing.sectionPadding(context),
        child: AppSpacing.constrained(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Dejá de perder ingresos\npor vergüenza.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Colibrí cobra por vos, '
                'mientras vos cuidás a tus pacientes.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sourceSans3(
                  fontSize: 18,
                  color: colorScheme.onPrimary.withAlpha(200),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton.icon(
                onPressed: () => context.go('/register'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  textStyle: GoogleFonts.sourceSans3(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Empezar ahora'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
