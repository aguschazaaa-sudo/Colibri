import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Hero section — the first visual impact of the landing page.
///
/// Contains heading with teal gradient, subtitle, CTA button,
/// and a decorative illustration on the right (desktop) or below (mobile).
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > AppSpacing.breakpointMd;

    return Padding(
      padding: AppSpacing.sectionPadding(context),
      child: AppSpacing.constrained(
        child: isWide ? const _DesktopHero() : const _MobileHero(),
      ),
    );
  }
}

// ── Desktop Layout ──────────────────────────────────────────────────────────

class _DesktopHero extends StatelessWidget {
  const _DesktopHero();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: _HeroCopy()),
        const SizedBox(width: AppSpacing.xxl),
        Expanded(child: _HeroIllustration()),
      ],
    );
  }
}

// ── Mobile Layout ───────────────────────────────────────────────────────────

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _HeroCopy(centered: true),
        const SizedBox(height: AppSpacing.xl),
        _HeroIllustration(),
      ],
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────────────

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Headline with gradient ──
        ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
              ).createShader(bounds),
          child: Text(
            'Que tu plata\nvuelva volando.',
            textAlign: textAlign,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white, // masked by shader
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Subtitle ──
        Text(
          'Automatizá recordatorios de pago por WhatsApp\n'
          'para tus pacientes. Sin tensión, sin olvidos,\n'
          'sin incomodar.',
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 18,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── CTA ──
        FilledButton.icon(
          onPressed: () {},
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
          icon: const Icon(Icons.rocket_launch_outlined, size: 20),
          label: const Text('Quiero probarlo'),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 440, maxHeight: 360),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withAlpha(120),
            colorScheme.tertiaryContainer.withAlpha(120),
          ],
        ),
        border: Border.all(color: colorScheme.outline.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mock patient rows ──
          _MockPatientRow(
            name: 'María López',
            amount: '\$12.500',
            color: colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MockPatientRow(
            name: 'Carlos Ruiz',
            amount: '\$4.800',
            color: colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MockPatientRow(
            name: 'Ana García',
            amount: '\$0',
            color: colorScheme.tertiary,
            isPaid: true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── WhatsApp preview ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFDCF8C6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '"Hola María, te recordamos que tenés '
                    'un saldo de \$12.500..."',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPatientRow extends StatelessWidget {
  const _MockPatientRow({
    required this.name,
    required this.amount,
    required this.color,
    this.isPaid = false,
  });

  final String name;
  final String amount;
  final Color color;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              name[0],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (isPaid)
            Icon(Icons.check_circle, color: color, size: 16)
          else
            const SizedBox.shrink(),
          const SizedBox(width: AppSpacing.xs),
          Text(
            amount,
            style: GoogleFonts.sourceSans3(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
