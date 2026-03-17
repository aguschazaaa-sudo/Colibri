import 'package:cobrador/presentation/home/widgets/dashboard_metrics.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/payments_provider.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/payment_history_item.dart';

class FinancesPage extends ConsumerWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid ?? '';
    final paymentsState = ref.watch(paymentsProvider(providerId));

    ref.registerShell(title: 'Finanzas');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paymentsProvider(providerId));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            sliver: SliverToBoxAdapter(child: DashboardMetrics()),
          ),
          SliverPadding(
            padding: AppSpacing.edgeInsetsH,
            sliver: SliverToBoxAdapter(
              child: Text(
                'Últimos Movimientos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          paymentsState.status.when(
            data: (_) => _buildPaymentsList(
              context,
              ref,
              paymentsState,
              providerId,
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(
    BuildContext context,
    WidgetRef ref,
    PaymentsState state,
    String providerId,
  ) {
    if (state.payments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text('No hay movimientos registrados')),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= state.payments.length) {
            if (state.hasMore) {
              Future.microtask(
                () => ref
                    .read(paymentsProvider(providerId).notifier)
                    .fetchNextPage(),
              );
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return null;
          }

          final payment = state.payments[index];
          return Column(
            children: [
              PaymentHistoryItem(payment: payment)
                  .animate(delay: (20 * (index % 8)).ms)
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideX(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
              if (index < state.payments.length - 1 || state.hasMore)
                const Divider(height: 1, indent: 72),
            ],
          );
        },
        childCount: state.payments.length + (state.hasMore ? 1 : 0),
      ),
    );
  }
}
