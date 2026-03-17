import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'widgets/settings_list_tile.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobrador/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    ref.registerShell(title: 'Ajustes');

    return ListView(
      children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Cuenta',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SettingsListTile(
              icon: Icons.person_outline_rounded,
              title: 'Perfil del Profesional',
              subtitle: 'Editar datos personales y de contacto',
              onTap: () {
                context.push('/settings/profile');
              },
            ),
            SettingsListTile(
              icon: Icons.credit_card_rounded,
              title: 'Suscripción',
              subtitle: 'Administrar tu plan activo',
              onTap: () {
                context.push('/subscription');
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Preferencias',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SettingsListTile(
              icon: Icons.event_busy_rounded,
              title: 'Días no laborables',
              subtitle: 'Feriados en los que no se cobran turnos',
              onTap: () {
                context.go('/settings/non-working-days');
              },
            ),
            SettingsListTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notificaciones',
              subtitle: 'Configurar alertas de turnos y pagos',
              onTap: () {
                context.push('/settings/notifications');
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Sesión',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SettingsListTile(
              icon: Icons.logout_rounded,
              title: 'Cerrar Sesión',
              isDestructive: true,
              onTap: () {
                ref.read(authNotifierProvider.notifier).logout();
              },
            ),
          ]
          .animate(interval: 50.ms)
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.05,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}
