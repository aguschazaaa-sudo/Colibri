import 'package:cobrador/presentation/home/widgets/home_drawer.dart';
import 'package:cobrador/presentation/providers/shell_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Persistent shell that wraps all authenticated main pages.
///
/// On large screens (≥900px) renders [HomeDrawer] permanently in a [Row].
/// On small screens renders a [Scaffold] with a hamburger-triggered drawer.
///
/// Each child page calls [shellStateProvider.notifier].setPage(...) to update
/// the AppBar title, actions and FAB.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  /// The active body content injected by [ShellRoute].
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ref.watch(shellStateProvider);
    final isLargeScreen = MediaQuery.sizeOf(context).width >= 900;

    if (isLargeScreen) {
      return Scaffold(
        appBar: _buildAppBar(context, shell),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permanent drawer — never animates
            RepaintBoundary(
              child: HomeDrawer(isPermanent: true),
            ),
            // Active page content
            Expanded(child: child),
          ],
        ),
        floatingActionButton: shell.floatingActionButton,
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, shell),
      drawer: const HomeDrawer(isPermanent: false),
      body: child,
      floatingActionButton: shell.floatingActionButton,
    );
  }

  AppBar _buildAppBar(BuildContext context, ShellState shell) {
    return AppBar(
      title: Text(shell.title),
      centerTitle: true,
      actions: [
        ...shell.actions,
      ],
    );
  }
}

/// Mixin for pages to register their shell configuration.
///
/// Usage: call [registerShell] inside the first build frame via
/// [WidgetsBinding.instance.addPostFrameCallback] or use
/// the [ShellPageMixin] helper.
extension ShellPageExtension on WidgetRef {
  void registerShell({
    required String title,
    List<Widget> actions = const [],
    Widget? floatingActionButton,
  }) {
    // Schedule after the current frame to avoid calling setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      read(shellStateProvider.notifier).setPage(
        title: title,
        actions: actions,
        floatingActionButton: floatingActionButton,
      );
    });
  }
}

/// GoRouter helper: reads the active path to set a default shell title.
/// Used as a fallback when a page hasn't registered yet.
String shellTitleForPath(String path) {
  if (path.startsWith('/home')) return 'Colibrí';
  if (path.startsWith('/patients')) return 'Pacientes';
  if (path.startsWith('/finances')) return 'Finanzas';
  if (path.startsWith('/reminders')) return 'Recordatorios';
  if (path.startsWith('/settings')) return 'Ajustes';
  return 'Colibrí';
}
