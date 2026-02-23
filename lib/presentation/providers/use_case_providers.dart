import 'package:cobrador/domain/use_cases/ledger_use_cases.dart';
import 'package:cobrador/domain/use_cases/patient_use_cases.dart';
import 'package:cobrador/domain/use_cases/provider_use_cases.dart';
import 'package:cobrador/domain/use_cases/trigger_whatsapp_reminders_use_case.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'use_case_providers.g.dart';

@Riverpod(keepAlive: true)
ApplyPaymentUseCase applyPaymentUseCase(ApplyPaymentUseCaseRef ref) {
  return ApplyPaymentUseCase();
}

@Riverpod(keepAlive: true)
CalculateInterestUseCase calculateInterestUseCase(
  CalculateInterestUseCaseRef ref,
) {
  return CalculateInterestUseCase();
}

@Riverpod(keepAlive: true)
CreatePatientUseCase createPatientUseCase(CreatePatientUseCaseRef ref) {
  final repo = ref.watch(patientRepositoryProvider);
  return CreatePatientUseCase(repo);
}

@Riverpod(keepAlive: true)
UpdatePatientUseCase updatePatientUseCase(UpdatePatientUseCaseRef ref) {
  final repo = ref.watch(patientRepositoryProvider);
  return UpdatePatientUseCase(repo);
}

@Riverpod(keepAlive: true)
UpdateProviderProfileUseCase updateProviderProfileUseCase(
  UpdateProviderProfileUseCaseRef ref,
) {
  final repo = ref.watch(providerRepositoryProvider);
  return UpdateProviderProfileUseCase(repo);
}

@Riverpod(keepAlive: true)
TriggerWhatsAppRemindersUseCase triggerWhatsAppRemindersUseCase(
  TriggerWhatsAppRemindersUseCaseRef ref,
) {
  final repo = ref.watch(communicationLogRepositoryProvider);
  return TriggerWhatsAppRemindersUseCase(repo);
}
