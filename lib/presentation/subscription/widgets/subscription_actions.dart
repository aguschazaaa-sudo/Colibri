import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/widgets/action_button.dart';

/// Action buttons for managing the current subscription plan.
///
/// Provides a tonal button to switch plans and a text button to cancel
/// the subscription entirely.
class SubscriptionActions extends StatelessWidget {
  /// Whether the user is currently on the Premium plan.
  final bool isPremium;

  /// Display name of the plan the user can switch to (e.g. "Premium" or "Basico").
  final String alternatePlanName;

  /// Formatted price string of the alternate plan (e.g. "\$20.000").
  final String alternatePlanPrice;

  /// Callback invoked when the user taps "Cambiar a ...".
  final Future<void> Function() onChangePlan;

  /// Callback invoked when the user taps "Cancelar suscripcion".
  final Future<void> Function() onCancel;

  const SubscriptionActions({
    super.key,
    required this.isPremium,
    required this.alternatePlanName,
    required this.alternatePlanPrice,
    required this.onChangePlan,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChangePlanButton(
          alternatePlanName: alternatePlanName,
          alternatePlanPrice: alternatePlanPrice,
          onChangePlan: onChangePlan,
        ),
        const SizedBox(height: AppSpacing.md),
        _CancelButton(
          onCancel: onCancel,
          errorColor: colorScheme.error,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }
}

/// Tonal button that displays the alternate plan name and price.
class _ChangePlanButton extends StatelessWidget {
  final String alternatePlanName;
  final String alternatePlanPrice;
  final Future<void> Function() onChangePlan;

  const _ChangePlanButton({
    required this.alternatePlanName,
    required this.alternatePlanPrice,
    required this.onChangePlan,
  });

  @override
  Widget build(BuildContext context) {
    return ActionButton.tonal(
      onPressed: onChangePlan,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text.rich(
        TextSpan(
          text: 'Cambiar a $alternatePlanName',
          children: [
            TextSpan(
              text: '  ·  $alternatePlanPrice/mes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Text button styled with the error color to cancel the subscription.
class _CancelButton extends StatelessWidget {
  final Future<void> Function() onCancel;
  final Color errorColor;

  const _CancelButton({
    required this.onCancel,
    required this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    return ActionButton.text(
      onPressed: onCancel,
      style: TextButton.styleFrom(
        foregroundColor: errorColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, color: errorColor),
          const SizedBox(width: AppSpacing.sm),
          const Text('Cancelar suscripcion'),
        ],
      ),
    );
  }
}
