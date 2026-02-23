import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Frosted card container for auth forms.
///
/// Provides consistent elevated container styling across auth pages.
/// Uses theme colors only — zero hardcoded colors.
class AuthCard extends StatelessWidget {
  final List<Widget> children;

  const AuthCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth =
        screenWidth < AppSpacing.breakpointSm ? double.infinity : 440.0;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
