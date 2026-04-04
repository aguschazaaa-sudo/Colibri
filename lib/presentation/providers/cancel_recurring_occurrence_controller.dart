import 'dart:async';

import 'package:cobrador/domain/cancel_recurring_occurrence_use_case.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cancel_recurring_occurrence_controller.g.dart';

/// Riverpod controller that exposes [cancelOccurrence] and surfaces
/// loading / error state for the cancel-single-recurring-occurrence feature.
@riverpod
class CancelRecurringOccurrenceController
    extends _$CancelRecurringOccurrenceController {
  @override
  FutureOr<void> build() {}

  Future<void> cancelOccurrence({
    required String providerId,
    required String patientId,
    required String recurringAppointmentId,
    required String dateKey,
    String? existingAppointmentId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = CancelRecurringOccurrenceUseCase(
        ref.read(ledgerRepositoryProvider),
      );
      final result = await useCase(
        providerId: providerId,
        patientId: patientId,
        recurringAppointmentId: recurringAppointmentId,
        dateKey: dateKey,
        existingAppointmentId: existingAppointmentId,
      );
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    });
  }
}
