import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'widgets/reminder_history_item.dart';

import 'package:cobrador/presentation/home/widgets/home_drawer.dart';
import 'package:cobrador/presentation/widgets/adaptive_scaffold.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AdaptiveScaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded),
            tooltip: 'Forzar Envío',
            onPressed: () {
              // TODO: Trigger manual sync/send
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
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Envío automático activo',
                            style: textTheme.titleMedium?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Los mensajes de cobranza se despachan el día 5 de cada mes a los pacientes con deuda.',
                        style: textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: AppSpacing.edgeInsetsH,
              child: Text(
                'Últimos Envíos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Mock list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ReminderHistoryItem(
                      patientName: 'Paciente ${index + 5}',
                      sentAt: DateTime.now().subtract(const Duration(days: 3)),
                      status: 'sent',
                      formatStatus: 'Enviado',
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
