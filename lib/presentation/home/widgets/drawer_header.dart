import 'package:flutter/material.dart';

import 'package:cobrador/domain/provider.dart' as domain;
import 'package:cobrador/presentation/home/widgets/atoms/plan_badge.dart';
import 'package:cobrador/presentation/home/widgets/atoms/provider_avatar.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';

/// Molecule: profile header shown at the top of [HomeDrawer].
///
/// Displays the provider's avatar, name, email and plan badge.
class DrawerProfileHeader extends StatelessWidget {
  const DrawerProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.plan,
    required this.isTrial,
    this.photoUrl,
  });

  final String name;
  final String email;
  final domain.SubscriptionPlan plan;
  final bool isTrial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
      child: Stack(
        children: [
          Positioned(
            top: -AppSpacing.xl,
            right: -AppSpacing.xl,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProviderAvatar(name: name, photoUrl: photoUrl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            email,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        PlanBadge(plan: plan, isTrial: isTrial),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
