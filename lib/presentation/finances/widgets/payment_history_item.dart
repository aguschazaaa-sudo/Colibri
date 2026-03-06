import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/presentation/providers/patient_name_provider.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/presentation/shared/modals/danger_confirmation_dialog.dart';
import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PaymentHistoryItem extends ConsumerWidget {
  final Payment payment;

  const PaymentHistoryItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientNameAsync = ref.watch(patientNameProvider(payment.patientId));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: AppSpacing.edgeInsetsH,
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.receipt_long_rounded),
      ),
      title: Skeletonizer(
        enabled: patientNameAsync.isLoading,
        child: Text(
          patientNameAsync.value ?? 'Cargando...',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      subtitle: Text(
        '${payment.date.day}/${payment.date.month}/${payment.date.year} • Acreditado',
        style: textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+\$${payment.amount.toStringAsFixed(0)}',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => DangerConfirmationDialog(
                          title: 'Cancelar Pago',
                          warningText:
                              'Al cancelar este pago, el monto se deducirá del saldo a favor del paciente. Si el saldo no alcanza, la diferencia volverá a figurar como deuda en turnos pasados.',
                          confirmationWord: 'cancelar',
                          confirmButtonText: 'Eliminar pago',
                        ),
                  );

                  if (confirmed == true && context.mounted) {
                    try {
                      // Note: We need LedgerProvider which requires providerId and patientId.
                      // Depending on what is available we could read the repo directly, but we have payment.
                      await ref
                          .read(
                            ledgerProvider(
                              providerId: payment.providerId,
                              patientId: payment.patientId,
                            ).notifier,
                          )
                          .deletePayment(payment.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pago cancelado con éxito.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
