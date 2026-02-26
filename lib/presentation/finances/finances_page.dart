import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'widgets/payment_history_item.dart';
import 'widgets/revenue_card.dart';

import 'package:cobrador/presentation/home/widgets/home_drawer.dart';
import 'package:cobrador/presentation/widgets/adaptive_scaffold.dart';

class FinancesPage extends StatelessWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AdaptiveScaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar Reporte',
            onPressed: () {
              // TODO: Export report
            },
          ),
        ],
      ),
      drawer: HomeDrawer(isPermanent: MediaQuery.sizeOf(context).width >= 900),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: RevenueCard(
                          title: 'Ingresos del mes',
                          amount: 150000,
                          icon: Icons.trending_up_rounded,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: RevenueCard(
                          title: 'Deuda por cobrar',
                          amount: 85000,
                          icon: Icons.hourglass_top_rounded,
                        )
                        .animate(delay: 50.ms)
                        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.edgeInsetsH,
              child: Text(
                'Últimos Movimientos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Mock list for now
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return PaymentHistoryItem(
                      patientName: 'Paciente ${index + 1}',
                      amount: 5000.0 * (index + 1),
                      date: DateTime.now().subtract(Duration(days: index)),
                      status: 'Acreditado',
                    )
                    .animate(delay: (50 * index).ms)
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideX(
                      begin: 0.05,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
