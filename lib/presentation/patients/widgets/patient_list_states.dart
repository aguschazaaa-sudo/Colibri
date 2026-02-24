import 'package:cobrador/presentation/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class PatientEmptyState extends StatelessWidget {
  const PatientEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('No tienes pacientes registrados.'),
        ],
      ),
    );
  }
}

class PatientErrorState extends StatelessWidget {
  final Object error;

  const PatientErrorState({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.edgeInsetsH,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Error al cargar pacientes: $error',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientLoadingSkeleton extends StatelessWidget {
  const PatientLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Only return the list of items since skeletonizer wraps everything
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Card(
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text('C')),
            title: Text('Cargando paciente'),
            subtitle: Text('Deuda: \$ 0'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded),
                Icon(Icons.attach_money_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}
