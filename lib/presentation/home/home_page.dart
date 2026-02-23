import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/home/widgets/dashboard_metrics.dart';
import 'package:cobrador/presentation/home/widgets/home_drawer.dart';
import 'package:cobrador/presentation/home/widgets/today_appointments.dart';
import 'package:cobrador/presentation/home/widgets/top_debtors.dart';
import 'package:cobrador/presentation/home/widgets/home_action_fab.dart';

/// Home page — shell for the authenticated experience.
///
/// Shows dashboard metrics, today's appointments, and top debtors.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colibrí'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Buscar paciente',
            onPressed: () {
              // TODO: Open universal search
            },
          ),
        ],
      ),
      drawer: const HomeDrawer(),
      body: _HomeBody(),
      floatingActionButton: const HomeActionFab(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh dashboard data
        await Future.delayed(const Duration(seconds: 1));
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
