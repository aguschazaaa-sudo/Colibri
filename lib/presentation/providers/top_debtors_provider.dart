import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'top_debtors_provider.g.dart';

@riverpod
Future<List<Patient>> topDebtors(Ref ref, String providerId) async {
  // Watch the asynchronous stream of patients
  final patients = await ref.watch(patientsProvider(providerId).future);

  // Filter those with debt > 0
  final debtors = patients.where((p) => p.totalDebt > 0).toList();

  // Sort descending by debt amount
  debtors.sort((a, b) => b.totalDebt.compareTo(a.totalDebt));

  // Return the top 5
  return debtors.take(5).toList();
}
