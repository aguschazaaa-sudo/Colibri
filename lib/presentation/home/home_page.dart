import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/home/widgets/dashboard_metrics.dart';
import 'package:cobrador/presentation/home/widgets/home_drawer.dart';
import 'package:cobrador/presentation/home/widgets/today_appointments.dart';
import 'package:cobrador/presentation/home/widgets/top_debtors.dart';
import 'package:cobrador/presentation/home/widgets/home_action_fab.dart';
import 'package:cobrador/presentation/home/widgets/universal_search_delegate.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/providers/top_debtors_provider.dart';

import 'package:cobrador/presentation/widgets/adaptive_scaffold.dart';

/// Home page — shell for the authenticated experience.
///
/// Shows dashboard metrics, today's appointments, and top debtors.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveScaffold(
      appBar: AppBar(
        title: const Text('Colibrí'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar paciente',
            onPressed: () {
              showSearch(
                context: context,
                delegate: UniversalSearchDelegate(ref),
              );
            },
          ),
        ],
      ),
      drawer: HomeDrawer(isPermanent: MediaQuery.sizeOf(context).width >= 900),
      body: const _HomeBody(),
      floatingActionButton: const HomeActionFab(),
    );
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

        // Small delay to let the UI show the refresh animation
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
