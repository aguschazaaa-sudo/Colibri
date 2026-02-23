import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ledger_provider.g.dart';

@riverpod
class Ledger extends _$Ledger {
  @override
  Stream<List<Appointment>> build({
    required String providerId,
    required String patientId,
  }) {
    final repository = ref.watch(ledgerRepositoryProvider);
    return repository.watchAppointments(
      providerId: providerId,
      patientId: patientId,
    );
  }

  /// Registra un pago y espera que la DB consolide el estado
  Future<void> registerPayment(Payment payment) async {
    // We skip Optimistic UI for now because the useCase requires the Patient entity,
    // which we don't have watched in this provider.

    final repository = ref.read(ledgerRepositoryProvider);
    final result = await repository.registerPayment(payment);

    result.fold(
      (failure) {
        throw Exception(failure.message);
      },
      (successPayment) {
        // Todo OK, the Stream will naturally emit the new documents shortly
      },
    );
  }

  /// Crea un nuevo turno
  Future<void> createAppointment(Appointment appointment) async {
    final repository = ref.read(ledgerRepositoryProvider);
    final result = await repository.createAppointment(appointment);

    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }
}

/// Provider extra para observar solo los pagos de un paciente
@riverpod
Stream<List<Payment>> patientPayments(
  PatientPaymentsRef ref, {
  required String providerId,
  required String patientId,
}) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.watchPayments(providerId: providerId, patientId: patientId);
}
