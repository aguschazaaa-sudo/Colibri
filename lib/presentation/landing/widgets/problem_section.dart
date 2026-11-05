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
              // ── Gancho ──
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'Las 10:00. Nadie entra.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Cuerpo ──
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Un turno asignado, una hora bloqueada, un paciente que no llegó.\n'
                  'Eso pasa seguido. Y casi nunca se cobra.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Cierre ──
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  '¿Le mandás un mensaje? ¿Lo llamás?\n'
                  '¿O lo dejás pasar para no incomodar?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
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
