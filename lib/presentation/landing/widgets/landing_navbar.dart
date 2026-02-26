import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

/// Top navigation bar for the landing page.
///
/// Shows the Colibrí logo, and "Iniciar Sesión" / CTA buttons.
/// Collapses to a hamburger menu on small screens.
class LandingNavbar extends StatelessWidget {
  const LandingNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > AppSpacing.breakpointSm;

    return Padding(
      padding: AppSpacing.horizontalPadding(
        context,
      ).copyWith(top: AppSpacing.md, bottom: AppSpacing.md),
      child: Row(
        children: [
          // ── Logo ──
          _Logo(colorScheme: colorScheme),
          const Spacer(),

          // ── Actions ──
          if (isWide) ...[
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                'Iniciar Sesión',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () => context.go('/register'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
              child: const Text('Empezar'),
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.menu, color: colorScheme.onSurface),
              onPressed: () => _showMobileMenu(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    child: const Text('Iniciar Sesión'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/register');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                    ),
                    child: const Text('Empezar'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/colibri_logo.png',
          width: 32,
          height: 32,
          errorBuilder:
              (_, __, ___) => Icon(
                Icons.flutter_dash,
                color: colorScheme.primary,
                size: 28,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Colibrí',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
