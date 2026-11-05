import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

/// Displays the current subscription status with semantic coloring.
///
/// Maps each [SubscriptionStatus] to a distinct color palette from the
/// Material 3 color scheme so the user can instantly gauge their account state.
class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({
    required this.status,
    this.expiresAt,
    this.cancelPending = false,
    super.key,
  });

  /// Current subscription status.
  final SubscriptionStatus status;

  /// When the subscription expires or renews. Shown as a secondary label.
  final DateTime? expiresAt;

  /// Whether a cancellation has been scheduled for [expiresAt].
  final bool cancelPending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final config = _StatusConfig.from(status, colorScheme);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      color: config.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusRow(
              config: config,
              textTheme: textTheme,
              expiresAt: expiresAt,
              dateFormat: dateFormat,
              isActive: status == SubscriptionStatus.active,
            ),
            if (cancelPending && expiresAt != null)
              _CancelPendingRow(
                colorScheme: colorScheme,
                textTheme: textTheme,
                expiresAt: expiresAt!,
                dateFormat: dateFormat,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.15);
  }
}

// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

/// Icon wrapped in a circular, semi-transparent container.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.config});

  final _StatusConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: config.iconColor.withValues(alpha: 0.15),
      ),
      child: Icon(config.icon, size: AppSpacing.xl, color: config.iconColor),
    );
  }
}

// ---------------------------------------------------------------------------
// Molecules
// ---------------------------------------------------------------------------

/// Main row: icon + status label + optional date.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.config,
    required this.textTheme,
    required this.expiresAt,
    required this.dateFormat,
    required this.isActive,
  });

  final _StatusConfig config;
  final TextTheme textTheme;
  final DateTime? expiresAt;
  final DateFormat dateFormat;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusIcon(config: config),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.label,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: config.foregroundColor,
                ),
              ),
              if (expiresAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    isActive
                        ? 'Proxima renovacion: ${dateFormat.format(expiresAt!)}'
                        : 'Vence el ${dateFormat.format(expiresAt!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: config.foregroundColor.withValues(alpha: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Additional info row shown when a cancellation is pending.
class _CancelPendingRow extends StatelessWidget {
  const _CancelPendingRow({
    required this.colorScheme,
    required this.textTheme,
    required this.expiresAt,
    required this.dateFormat,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final DateTime expiresAt;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: AppSpacing.xl),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: AppSpacing.md,
              color: colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Se cancelara el ${dateFormat.format(expiresAt)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Configuration helper
// ---------------------------------------------------------------------------

/// Resolves visual properties based on the subscription status.
class _StatusConfig {
  const _StatusConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    required this.icon,
    required this.label,
  });

  factory _StatusConfig.from(
    SubscriptionStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case SubscriptionStatus.active:
        return _StatusConfig(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          iconColor: colorScheme.primary,
          icon: Icons.check_circle,
          label: 'Suscripcion activa',
        );
      case SubscriptionStatus.pastDue:
        return _StatusConfig(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          iconColor: colorScheme.secondary,
          icon: Icons.warning_amber_rounded,
          label: 'Pago pendiente',
        );
      case SubscriptionStatus.suspended:
        return _StatusConfig(
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          iconColor: colorScheme.error,
          icon: Icons.block,
          label: 'Suscripcion suspendida',
        );
    }
  }

  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final IconData icon;
  final String label;
}
