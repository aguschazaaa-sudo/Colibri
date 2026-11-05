import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/provider_profile_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Organism — Banner that prompts the logged-in professional to complete their
/// profile when [Provider.profession] is null or empty.
///
/// The banner is dismissible for the current session. Once the profession is
/// saved, the reactive stream causes this widget to disappear automatically.
class ProfileSetupBanner extends ConsumerStatefulWidget {
  const ProfileSetupBanner({super.key});

  @override
  ConsumerState<ProfileSetupBanner> createState() => _ProfileSetupBannerState();
}

class _ProfileSetupBannerState extends ConsumerState<ProfileSetupBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final profileAsync = ref.watch(providerProfileProvider(uid));

    return profileAsync.when(
      data: (provider) {
        final needsSetup =
            provider == null ||
            provider.profession == null ||
            provider.profession!.trim().isEmpty;

        if (!needsSetup) return const SizedBox.shrink();

        return _BannerCard(
          onDismiss: () => setState(() => _dismissed = true),
          onTap: () => context.go('/settings/profile'),
        )
            .animate()
            .fadeIn(duration: 300.ms, curve: Curves.easeOut)
            .slideY(begin: -0.06, end: 0, duration: 300.ms, curve: Curves.easeOut);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Molecule: visual card with icon, texts, action and dismiss ────────────────

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.onDismiss, required this.onTap});

  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Card(
        elevation: 0,
        color: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          side: BorderSide(
            color: colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BannerIcon(color: colorScheme.onSecondaryContainer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _BannerText(
                    textTheme: textTheme,
                    onColor: colorScheme.onSecondaryContainer,
                  ),
                ),
                _DismissButton(
                  onDismiss: onDismiss,
                  color: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Atoms ─────────────────────────────────────────────────────────────────────

class _BannerIcon extends StatelessWidget {
  const _BannerIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Icon(Icons.person_outline_rounded, color: color, size: 28),
    );
  }
}

class _BannerText extends StatelessWidget {
  const _BannerText({required this.textTheme, required this.onColor});

  final TextTheme textTheme;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completá tu perfil',
          style: textTheme.titleSmall?.copyWith(
            color: onColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Definí tu profesión y configurá tus días no laborales para aprovechar al máximo la app.',
          style: textTheme.bodySmall?.copyWith(
            color: onColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onDismiss, required this.color});

  final VoidCallback onDismiss;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.close_rounded, size: 18, color: color.withValues(alpha: 0.7)),
      tooltip: 'Cerrar',
      onPressed: onDismiss,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
