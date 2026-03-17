import 'package:cobrador/presentation/home/widgets/universal_search_delegate.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'widgets/add_patient_modal.dart';
import 'widgets/patient_list_states.dart';
import 'widgets/patient_list_tile.dart';

class PatientsPage extends ConsumerWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final providerId = auth.currentUser?.uid;

    if (providerId == null) {
      return const Center(child: Text('Error: Usuario no autenticado.'));
    }

    final patientsAsync = ref.watch(patientsProvider(providerId));

    // Register shell with search action and FAB.
    ref.registerShell(
      title: 'Pacientes',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => showSearch(
            context: context,
            delegate: UniversalSearchDelegate(ref),
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddPatientModal(context, ref),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );

    return patientsAsync.when(
      data: (patients) {
        if (patients.isEmpty) {
          return const PatientEmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            return PatientListTile(patient: patients[index])
                .animate(delay: (50 * index).ms)
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                );
          },
        );
      },
      loading: () => const Skeletonizer(
        enabled: true,
        child: PatientLoadingSkeleton(),
      ),
      error: (e, st) => PatientErrorState(error: e),
    );
  }
}
