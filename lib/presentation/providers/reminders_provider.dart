import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/providers/use_case_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminders_provider.g.dart';

@riverpod
class RemindersController extends _$RemindersController {
  @override
  FutureOr<void> build() {
    // Initial state is nothing
  }

  Future<void> triggerReminder(Patient patient) async {
    state = const AsyncValue.loading();

    final useCase = ref.read(triggerWhatsAppRemindersUseCaseProvider);
    final result = await useCase.execute(patient);

    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (log) {
        state = const AsyncValue.data(null);
      },
    );
  }
}
