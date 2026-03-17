import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cobrador/presentation/landing/widgets/scroll_reveal_wrapper.dart';

/// Visual timeline explaining the 3-step flow:
/// 1. Register patients & appointments
/// 2. Colibrí calculates debts
/// 3. WhatsApp does the rest
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  static const _steps = [
    _StepData(
      number: '1',
      icon: Icons.person_add_alt_1_outlined,
      title: 'Registrá',
      description: 'Cargá tus pacientes y turnos en segundos.',
    ),
    _StepData(
      number: '2',
      icon: Icons.calculate_outlined,
      title: 'Colibrí calcula',
      description: 'El sistema lleva la cuenta de cada deuda automáticamente.',
    ),
    _StepData(
      number: '3',
      icon: Icons.send_rounded,
      title: 'WhatsApp avisa',
      description: 'Tus pacientes reciben un recordatorio amable cada mes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > AppSpacing.breakpointMd;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(30),
      ),
      child: Padding(
        padding: AppSpacing.sectionPadding(context),
        child: AppSpacing.constrained(
          child: Column(
            children: [
              Text(
                'Así de fácil',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ScrollRevealWrapper(
                childBuilder: (context, isVisible) {
                  if (isWide) {
                    return _DesktopSteps(steps: _steps, isVisible: isVisible);
                  } else {
                    return _MobileSteps(steps: _steps, isVisible: isVisible);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop: horizontal with connectors ─────────────────────────────────────

class _DesktopSteps extends StatelessWidget {
  const _DesktopSteps({required this.steps, required this.isVisible});

  final List<_StepData> steps;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: SizedBox(
                    width: 48,
                    child: Divider(color: colorScheme.outline, thickness: 2),
                  ),
                )
                .animate(target: isVisible ? 1 : 0)
                .fadeIn(delay: ((i * 300) + 150).ms, duration: 300.ms)
                .scaleX(alignment: Alignment.centerLeft),
          Expanded(
            child: _StepTile(data: steps[i])
                .animate(target: isVisible ? 1 : 0)
                .fadeIn(delay: (i * 300).ms, duration: 400.ms)
                .slideX(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ],
      ],
    );
  }
}

// ── Mobile: vertical ────────────────────────────────────────────────────────

class _MobileSteps extends StatelessWidget {
  const _MobileSteps({required this.steps, required this.isVisible});

  final List<_StepData> steps;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          _StepTile(data: steps[i])
              .animate(target: isVisible ? 1 : 0)
              .fadeIn(delay: (i * 150).ms, duration: 400.ms)
              .slideY(
                begin: 0.1,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
        ],
      ],
    );
  }
}

// ── Step Tile ───────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  const _StepTile({required this.data});

  final _StepData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Numbered circle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            data.number,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Icon(data.icon, size: 32, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.sm),

        Text(
          data.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Data Model ──────────────────────────────────────────────────────────────

class _StepData {
  const _StepData({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
}
