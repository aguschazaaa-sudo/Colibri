import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patient_name_provider.g.dart';

@riverpod
Future<String> patientName(Ref ref, String patientId) async {
  if (patientId.isEmpty) return 'Paciente Desconocido';

  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final providerId = auth.currentUser?.uid ?? '';

  if (providerId.isEmpty) return 'Desconocido';

  try {
    final doc =
        await firestore
            .collection('providers')
            .doc(providerId)
            .collection('patients')
            .doc(patientId)
            .get();

    if (doc.exists) {
      return doc.data()?['name'] as String? ?? 'Desconocido';
    }
    return 'Desconocido';
  } catch (e) {
    return 'Error';
  }
}
