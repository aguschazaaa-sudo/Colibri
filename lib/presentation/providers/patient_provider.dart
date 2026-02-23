import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:cobrador/presentation/providers/use_case_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patient_provider.g.dart';

@riverpod
class Patients extends _$Patients {
  @override
  Stream<List<Patient>> build(String providerId) {
    final repository = ref.watch(patientRepositoryProvider);
    return repository.watchPatients(providerId);
  }

  Future<void> addPatient(Patient patient) async {
    final useCase = ref.read(createPatientUseCaseProvider);
    final result = await useCase.execute(patient);

    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }

  Future<void> updatePatient(Patient patient) async {
    final useCase = ref.read(updatePatientUseCaseProvider);
    final result = await useCase.execute(patient);

    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }
}
