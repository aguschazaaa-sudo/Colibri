import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/presentation/providers/reminders_provider.dart';
import 'package:cobrador/presentation/reminders/widgets/reminder_history_item.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cobrador/providers/auth_providers.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(authStateProvider).valueOrNull;
    final providerId = provider?.id ?? '';

    ref.registerShell(title: 'Recordatorios');

    if (providerId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return _RemindersBody(providerId: providerId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _RemindersBody extends ConsumerWidget {
  const _RemindersBody({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(communicationLogsProvider(providerId));
    final stats = ref.watch(remindersStatsProvider(providerId));
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Teal Hero Header ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroHeader(colorScheme: colorScheme),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Stats row ─────────────────────────────────────────────
              _StatsRow(stats: stats, colorScheme: colorScheme),

              const SizedBox(height: AppSpacing.lg),

              // ── Section title ─────────────────────────────────────────
              Text(
                'Últimos Envíos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ]),
          ),
        ),

        // ── Log list ───────────────────────────────────────────────────
        logsAsync.when(
          loading: () => _SkeletonList(),
          error: (err, _) => _ErrorSliver(message: err.toString()),
          data: (logs) {
            if (logs.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              );
            }
            return _LogList(logs: logs);
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return ClipPath(
      clipper: const _HeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              // Slightly darker/deeper teal for depth
              Color.alphaBlend(
                Colors.black.withValues(alpha: 0.1),
                colorScheme.primary,
              ),
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          isDesktop ? 80 : 60, // extra to show behind stat cards
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Envío automático activo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80), // Vibrant Green
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SISTEMA ONLINE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Los recordatorios de cobro se enviarán el '
                  'día 28 de cada mes a los pacientes con deuda pendiente.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  const _HeaderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    final controlPoint = Offset(size.width / 2, size.height);
    final endPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row (floats over the header bottom edge)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.colorScheme});

  final RemindersStats stats;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final nextLabel = DateFormat('dd/MM').format(stats.nextSendDate);

    return Transform.translate(
      offset: const Offset(0, -AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total del Mes',
              value: '${stats.totalThisMonth}',
              sublabel: 'Envíos exitosos',
              color: colorScheme.primaryContainer,
              textColor: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'Próximo Envío',
              value: nextLabel,
              sublabel: 'Programado',
              color: colorScheme.secondaryContainer,
              textColor: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
    required this.textColor,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              sublabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log list
// ─────────────────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  const _LogList({required this.logs});
  final List<CommunicationLog> logs;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ReminderHistoryItem(log: log);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fakeLogs = List.generate(
      5,
      (i) => CommunicationLog(
        id: '$i',
        patientId: 'p$i',
        providerId: 'prov',
        messageId: 'msg$i',
        sentAt: DateTime.now().subtract(Duration(days: i)),
        status: 'sent',
        totalDebtAtThatTime: 5000,
        patientName: 'Nombre Apellido',
      ),
    );

    return SliverList.separated(
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemCount: fakeLogs.length,
      itemBuilder: (context, index) {
        return Skeletonizer(
          child: ReminderHistoryItem(log: fakeLogs[index]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_chat_unread_rounded,
              size: 56,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sin envíos aún',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'El historial de recordatorios aparecerá aquí una vez que se realice el primer envío el día 28.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorSliver extends StatelessWidget {
  const _ErrorSliver({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error al cargar historial',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
