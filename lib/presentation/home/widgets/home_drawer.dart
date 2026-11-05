import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cobrador/domain/provider.dart' as domain;
import 'package:cobrador/presentation/home/widgets/drawer_header.dart' show DrawerProfileHeader;
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/providers/auth_providers.dart';

class HomeDrawer extends ConsumerWidget {
  final bool isPermanent;

  const HomeDrawer({super.key, this.isPermanent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final provider = authState.value;
    final photoUrl = firebase_auth.FirebaseAuth.instance.currentUser?.photoURL;

    return Drawer(
      child: Column(
        children: [
          DrawerProfileHeader(
            name: provider?.name ?? 'Profesional',
            email: provider?.email ?? '',
            plan: provider?.plan ?? domain.SubscriptionPlan.none,
            isTrial: provider?.isTrial ?? true,
            photoUrl: photoUrl,
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio'),
            selected: currentPath.startsWith('/home'),
            selectedColor: colorScheme.primary,
            selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            onTap: () {
              if (!isPermanent) Navigator.pop(context);
              context.go('/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Directorio de Pacientes'),
            selected: currentPath.startsWith('/patients'),
            selectedColor: colorScheme.primary,
            selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            onTap: () {
              if (!isPermanent) Navigator.pop(context);
              context.go('/patients');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Finanzas'),
            selected: currentPath.startsWith('/finances'),
            selectedColor: colorScheme.primary,
            selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            onTap: () {
              if (!isPermanent) Navigator.pop(context);
              context.go('/finances');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Recordatorios'),
            selected: currentPath.startsWith('/reminders'),
            selectedColor: colorScheme.primary,
            selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            onTap: () {
              if (!isPermanent) Navigator.pop(context);
              context.go('/reminders');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Ajustes'),
            selected: currentPath.startsWith('/settings'),
            selectedColor: colorScheme.primary,
            selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            onTap: () {
              if (!isPermanent) Navigator.pop(context);
              context.go('/settings');
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
