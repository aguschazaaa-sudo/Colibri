import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminders_provider.g.dart';

/// Notifier for the Reminders page.
///
/// State: `AsyncValue<int?>` — null = idle, int = queued count from last send.
@riverpod
class RemindersController extends _$RemindersController {
  @override
  AsyncValue<int?> build() => const AsyncData(null);

  /// Calls the `triggerManualReminders` Cloud Function to bulk-queue
  /// WhatsApp reminders for all patients of the current provider with debt.
  Future<void> triggerBulkSend() async {
    state = const AsyncLoading();

    final repo = ref.read(communicationLogRepositoryProvider);
    final result = await repo.triggerBulkReminders();

    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (queued) => state = AsyncData(queued),
    );
  }
}
