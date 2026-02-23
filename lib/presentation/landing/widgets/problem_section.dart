import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Awareness section that presents an impactful statistic about
/// uncollected health debts.
class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(40),
      ),
      child: Padding(
        padding: AppSpacing.sectionPadding(context),
        child: AppSpacing.constrained(
          child: Column(
            children: [
              // ── Stat number ──
              Text(
                '40%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Description ──
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(
                  'de los profesionales de salud independientes pierde '
                  'ingresos por deudas no cobradas.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  'No es falta de pacientes — es falta de herramientas.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
