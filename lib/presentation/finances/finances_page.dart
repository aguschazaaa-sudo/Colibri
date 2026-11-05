import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/payments_provider.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/finances_info_panel.dart';
import 'widgets/payment_scroll_view.dart';

class FinancesPage extends ConsumerWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid ?? '';

    ref.registerShell(title: 'Finanzas');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return _WideLayout(providerId: providerId);
        }
        return _NarrowLayout(providerId: providerId);
      },
    );
  }
}

class _NarrowLayout extends ConsumerWidget {
  final String providerId;
  const _NarrowLayout({required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsState = ref.watch(paymentsProvider(providerId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paymentsProvider(providerId));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: PaymentScrollView(
        providerId: providerId,
        paymentsState: paymentsState,
      ),
    );
  }
}

class _WideLayout extends ConsumerWidget {
  final String providerId;
  const _WideLayout({required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsState = ref.watch(paymentsProvider(providerId));
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(paymentsProvider(providerId));
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: PaymentScrollView(
              providerId: providerId,
              paymentsState: paymentsState,
            ),
          ),
        ),
        VerticalDivider(width: 1, color: colorScheme.outlineVariant),
        const SizedBox(
          width: 300,
          child: FinancesInfoPanel(),
        ),
      ],
    );
  }
}
