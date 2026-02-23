import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/top_debtors_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:intl/intl.dart';

class TopDebtorsSection extends ConsumerWidget {
  const TopDebtorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) return const SizedBox.shrink();

    final topDebtorsAsync = ref.watch(topDebtorsProvider(providerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.edgeInsetsH,
          child: Text(
            'Requieren Atención',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        topDebtorsAsync.when(
          data: (debtors) {
            if (debtors.isEmpty) {
              return Padding(
                padding: AppSpacing.edgeInsetsH,
                child: Text(
                  'No hay pacientes con deuda.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            final currencyFormat = NumberFormat.currency(
              locale: 'es_AR',
              symbol: '\$',
              decimalDigits: 2,
            );

            return ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: debtors.length,
              itemBuilder: (context, index) {
                final debtor = debtors[index];
                return _DebtorTile(
                  name: debtor.name,
                  debtAmount: currencyFormat.format(debtor.totalDebt),
                  unpaidCount: 1,
                );
              },
            );
          },
          loading:
              () => Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return const _DebtorTile(
                      name: 'Cargando nombre...',
                      debtAmount: '\$ 00,000.00',
                      unpaidCount: 1,
                    );
                  },
                ),
              ),
          error:
              (e, st) => Padding(
                padding: AppSpacing.edgeInsetsH,
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Error: $e',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}

class _DebtorTile extends StatelessWidget {
  final String name;
  final String debtAmount;
  final int unpaidCount;

  const _DebtorTile({
    required this.name,
    required this.debtAmount,
    required this.unpaidCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Rule: Yellow for up to 2 appointments, Red for 3+
    final isCritical = unpaidCount >= 3;
    final alertColor =
        colorScheme.inversePrimary; // A variation for warning state from theme
    final alertContainer = colorScheme.surfaceContainerHighest;

    final indicatorColor = isCritical ? colorScheme.error : alertColor;
    final indicatorContainerColor =
        isCritical ? colorScheme.errorContainer : alertContainer;

    return ListTile(
      contentPadding: AppSpacing.edgeInsetsH,
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Text(
          name.substring(0, 1),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
      title: Text(
        name,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$unpaidCount turno${unpaidCount > 1 ? 's' : ''} sin pagar',
        style: textTheme.bodySmall,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: indicatorContainerColor,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Text(
          debtAmount,
          style: textTheme.labelLarge?.copyWith(
            color: indicatorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        // TODO: Navigate to patient's detailed page
      },
    );
  }
}
