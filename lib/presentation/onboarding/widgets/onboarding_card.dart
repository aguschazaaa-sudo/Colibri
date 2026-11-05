import 'package:flutter/material.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';

class OnboardingPageContent extends StatelessWidget {
  final String title;
  final String body;
  final Widget graphic;
  final String? badgeText;

  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.body,
    required this.graphic,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: Center(
                  child: graphic,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeText!,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg), // Space for dots/buttons which are in parent
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingGraphic extends StatelessWidget {
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool animate;

  const OnboardingGraphic({
    super.key,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background soft shape 1
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                secondaryColor.withAlpha(100),
                secondaryColor.withAlpha(0),
              ],
            ),
          ),
        ),
        // Background soft shape 2
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withAlpha(50),
            ),
          ),
        ),
        // Main icon container
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: secondaryColor.withAlpha(20),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: primaryColor.withAlpha(15),
                blurRadius: 15,
                spreadRadius: -5,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 80,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
