import 'package:flutter/material.dart';
import 'package:cobrador/presentation/shared/modals/create_patient_sheet.dart';
import 'package:cobrador/presentation/shared/modals/create_appointment_sheet.dart';
import 'package:cobrador/presentation/shared/modals/create_recurring_appointment_sheet.dart';
import 'package:cobrador/presentation/shared/modals/create_payment_sheet.dart';

class HomeActionsSheet extends StatelessWidget {
  const HomeActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(102),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('¿Qué deseas hacer?', style: textTheme.titleLarge),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person_add_rounded),
            title: const Text('Añadir Paciente'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                builder: (context) => const CreatePatientSheet(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Agendar Turno'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                builder: (context) => const CreateAppointmentSheet(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_repeat_rounded),
            title: const Text('Abono Recurrente'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                builder: (context) => const CreateRecurringAppointmentSheet(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money_rounded),
            title: const Text('Añadir Pago'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                builder: (context) => const CreatePaymentSheet(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
