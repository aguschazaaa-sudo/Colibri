import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Horizontal divider with centered label, typically "o".
///
/// Example: ─────── o ───────
class OrDivider extends StatelessWidget {
  final String label;

  const OrDivider({super.key, this.label = 'o'});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: colorScheme.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(color: colorScheme.outline)),
        ],
      ),
    );
  }
}
