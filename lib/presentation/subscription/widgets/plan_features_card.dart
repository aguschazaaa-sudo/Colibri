import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Displays the features included in the user's current subscription plan.
///
/// Shows basic features for all plans and additional premium features
/// when [isPremium] is `true`.
class PlanFeaturesCard extends StatelessWidget {
  /// Whether the current plan is Premium.
  final bool isPremium;

  const PlanFeaturesCard({super.key, required this.isPremium});

  static const _basicFeatures = [
    'Registro ilimitado de pacientes',
    'Seguimiento automático de deudas por WhatsApp',
    'Reportes financieros mensuales',
    'Organización de tu día a día',
  ];

  static const _premiumExtras = [
    'Recordatorios de turnos por WhatsApp',
    'Acceso a nuevas funcionalidades primero',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final features = [
      ..._basicFeatures,
      if (isPremium) ..._premiumExtras,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu plan incluye',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: features
                  .map((feature) => _FeatureRow(text: feature))
                  .toList(),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.15);
  }
}

/// A single feature row with a check icon and descriptive text.
class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
