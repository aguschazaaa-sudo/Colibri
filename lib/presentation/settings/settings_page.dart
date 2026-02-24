import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'widgets/settings_list_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
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
                  // TODO: Navigate to Profile
                },
              ),
              SettingsListTile(
                icon: Icons.credit_card_rounded,
                title: 'Suscripción',
                subtitle: 'Administrar tu plan activo',
                onTap: () {
                  // TODO: Navigate to Subscription
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
                icon: Icons.notifications_none_rounded,
                title: 'Notificaciones',
                subtitle: 'Configurar alertas de turnos y pagos',
                onTap: () {
                  // TODO: Navigate to Notifications Settings
                },
              ),
              SettingsListTile(
                icon: Icons.color_lens_outlined,
                title: 'Apariencia',
                subtitle: 'Tema claro, oscuro o del sistema',
                onTap: () {
                  // TODO: Navigate to Theme Settings
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
                  // TODO: Handle logout
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
      ),
    );
  }
}
