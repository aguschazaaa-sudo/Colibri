import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/home/widgets/dashboard_metrics.dart';
import 'package:cobrador/presentation/home/widgets/profile_setup_banner.dart';
import 'package:cobrador/presentation/home/widgets/home_action_fab.dart';
import 'package:cobrador/presentation/home/widgets/today_appointments.dart';
import 'package:cobrador/presentation/home/widgets/top_debtors.dart';
import 'package:cobrador/presentation/home/widgets/universal_search_delegate.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/top_debtors_provider.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';

/// Home page — registers its title, actions and FAB in the AppShell.
///
/// On mobile (< 900px) the [TopDebtorsSection] is hidden from the main body
/// and accessible via an end drawer (toggled by the AppBar action button).
/// On desktop (≥ 900px) it appears inline as a side column.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= AppSpacing.breakpointMd;

    ref.registerShell(
      title: 'Colibrí',
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Buscar paciente',
          onPressed: () {
            showSearch(context: context, delegate: UniversalSearchDelegate(ref));
          },
        ),
        // Mobile only: button to open the top-debtors end drawer
        if (!isWide)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: 'Mayores deudores',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
      ],
      floatingActionButton: const HomeActionFab(),
      endDrawer: isWide ? null : const _TopDebtorsDrawer(),
    );

    return _HomeBody(isWide: isWide);
  }
}

// ── Organism: end-drawer wrapper for mobile ───────────────────────────────────

class _TopDebtorsDrawer extends StatelessWidget {
  const _TopDebtorsDrawer();

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: TopDebtorsSection(),
        ),
      ),
    );
  }
}

// ── Organism: home body ───────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isWide) {
      return const _DesktopLayout();
    }
    return const _MobileLayout();
  }
}

// ── Desktop layout: two-column Row ───────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              ProfileSetupBanner(),
              DashboardMetrics(),
              SizedBox(height: AppSpacing.md),
              Expanded(child: TodayAppointmentsSection()),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: TopDebtorsSection(),
          ),
        ),
      ],
    );
  }
}

// ── Mobile layout: single column ─────────────────────────────────────────────

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    return RefreshIndicator(
      onRefresh: () async {
        if (providerId != null) {
          ref.invalidate(ledgerProvider(providerId: providerId, patientId: ''));
          ref.invalidate(topDebtorsProvider(providerId));
          ref.invalidate(patientsProvider(providerId));
        }
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: const Column(
        children: [
          ProfileSetupBanner(),
          DashboardMetrics(),
          SizedBox(height: AppSpacing.md),
          Expanded(child: TodayAppointmentsSection()),
        ],
      ),
    );
  }
}
