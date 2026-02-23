import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            accountName: Text(
              authState.value?.name ?? 'Profesional',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            accountEmail: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2), // Active tint
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    'Suscripción Activa',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio'),
            selected: true,
            selectedColor: colorScheme.primary,
            selectedTileColor: colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            onTap: () {
              Navigator.pop(context);
              // Ya estamos en home
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Directorio de Pacientes'),
            onTap: () {
              Navigator.pop(context);
              context.push('/patients');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Finanzas'),
            onTap: () {
              Navigator.pop(context);
              context.push('/finances');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Recordatorios'),
            onTap: () {
              Navigator.pop(context);
              context.push('/reminders');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Ajustes'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: colorScheme.error),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
