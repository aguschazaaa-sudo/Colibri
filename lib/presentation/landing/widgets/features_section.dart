import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Three feature cards: automated reminders, debt control, relationship care.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _features = [
    _FeatureData(
      icon: Icons.notifications_active_outlined,
      title: 'Recordatorios automáticos',
      description:
          'WhatsApp una vez al mes, sin que muevas un dedo. '
          'Colibrí se encarga.',
    ),
    _FeatureData(
      icon: Icons.bar_chart_rounded,
      title: 'Control total',
      description: 'Quién debe, cuánto y desde cuándo — todo de un vistazo.',
    ),
    _FeatureData(
      icon: Icons.handshake_outlined,
      title: 'Tu vínculo intacto',
      description:
          'El mensaje lo manda Colibrí, no vos. '
          'Tu relación con el paciente se preserva.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > AppSpacing.breakpointMd;

    return Padding(
      padding: AppSpacing.sectionPadding(context),
      child: AppSpacing.constrained(
        child: Column(
          children: [
            Text(
              '¿Por qué Colibrí?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (isWide)
              const _DesktopGrid(features: _features)
            else
              const _MobileList(features: _features),
          ],
        ),
      ),
    );
  }
}

// ── Desktop: 3-column grid ──────────────────────────────────────────────────

class _DesktopGrid extends StatelessWidget {
  const _DesktopGrid({required this.features});

  final List<_FeatureData> features;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            Expanded(child: _FeatureCard(data: features[i])),
          ],
        ],
      ),
    );
  }
}

// ── Mobile: stacked cards ───────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  const _MobileList({required this.features});

  final List<_FeatureData> features;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < features.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _FeatureCard(data: features[i]),
        ],
      ],
    );
  }
}

// ── Feature Card ────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final _FeatureData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Model ──────────────────────────────────────────────────────────────

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
