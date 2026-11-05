import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FinancesInfoPanel extends StatelessWidget {
  const FinancesInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - AppSpacing.lg * 2,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 72,
                  color: colorScheme.primary.withValues(alpha: 0.18),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Cómo funciona',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._tips.asMap().entries.map(
                  (entry) => _TipItem(
                    icon: entry.value.$1,
                    title: entry.value.$2,
                    description: entry.value.$3,
                    delay: (80 * entry.key).ms,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _InfoBanner(
                  icon: Icons.lightbulb_outline_rounded,
                  text:
                      'Registrá pagos desde el perfil del paciente, en la sección de turnos impagos.',
                  color: colorScheme.tertiaryContainer,
                  onColor: colorScheme.onTertiaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _tips = [
  (
    Icons.sort_rounded,
    'Orden FIFO',
    'Los pagos se aplican primero a los saldos más antiguos del paciente.',
  ),
  (
    Icons.undo_rounded,
    'Cancelación de pagos',
    'Cancelar un pago devuelve el saldo pendiente a los turnos correspondientes.',
  ),
  (
    Icons.calendar_month_rounded,
    'Ingreso mensual',
    'El total ingresado se resetea el 1 de cada mes para reflejar el período actual.',
  ),
  (
    Icons.link_rounded,
    'Vinculación a turnos',
    'Cada pago puede estar asociado a uno o varios turnos del paciente.',
  ),
];

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Duration delay;

  const _TipItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Icon(
              icon,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate(delay: delay).fadeIn(duration: 400.ms).slideX(
            begin: 0.06,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color onColor;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: onColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: onColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 350.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
