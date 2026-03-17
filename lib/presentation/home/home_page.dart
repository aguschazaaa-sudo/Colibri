import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/home/widgets/dashboard_metrics.dart';
import 'package:cobrador/presentation/home/widgets/home_action_fab.dart';
import 'package:cobrador/presentation/home/widgets/today_appointments.dart';
import 'package:cobrador/presentation/home/widgets/top_debtors.dart';
import 'package:cobrador/presentation/home/widgets/universal_search_delegate.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/top_debtors_provider.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';

/// Home page — registers its title + FAB in the AppShell and returns its body.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      ],
      floatingActionButton: const HomeActionFab(),
    );

    return const _HomeBody();
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        final auth = ref.read(firebaseAuthProvider);
        final providerId = auth.currentUser?.uid;

        if (providerId != null) {
          ref.invalidate(ledgerProvider(providerId: providerId, patientId: ''));
          ref.invalidate(topDebtorsProvider(providerId));
          ref.invalidate(patientsProvider(providerId));
        }

        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: const [
          DashboardMetrics(),
          SizedBox(height: AppSpacing.xl),
          TodayAppointmentsSection(),
          SizedBox(height: AppSpacing.xl),
          TopDebtorsSection(),
        ],
      ),
    );
  }
}
