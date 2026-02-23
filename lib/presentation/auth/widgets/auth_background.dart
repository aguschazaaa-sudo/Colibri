import 'package:flutter/material.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Full-screen gradient background used on all auth pages.
///
/// Uses the theme's primary color family for the gradient.
/// Adds a subtle decorative circle pattern for depth.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.85),
              colorScheme.primaryContainer.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            _DecorativeCircle(
              top: -80,
              right: -60,
              size: 240,
              color: colorScheme.onPrimary.withValues(alpha: 0.05),
            ),
            _DecorativeCircle(
              bottom: -100,
              left: -80,
              size: 300,
              color: colorScheme.onPrimary.withValues(alpha: 0.04),
            ),
            _DecorativeCircle(
              top: MediaQuery.sizeOf(context).height * 0.4,
              right: -40,
              size: 160,
              color: colorScheme.onPrimary.withValues(alpha: 0.03),
            ),
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: AppSpacing.sectionPadding(
                    context,
                    verticalOverride: AppSpacing.lg,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  const _DecorativeCircle({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
