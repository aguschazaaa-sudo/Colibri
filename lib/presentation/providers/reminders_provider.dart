import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminders_provider.g.dart';

// ---------------------------------------------------------------------------
// Stream: last 30 communication logs for the given provider
// ---------------------------------------------------------------------------

@riverpod
Stream<List<CommunicationLog>> communicationLogs(
  Ref ref,
  String providerId,
) {
  final repo = ref.watch(communicationLogRepositoryProvider);
  return repo.watchCommunicationLogs(providerId);
}

// ---------------------------------------------------------------------------
// Stats derived from the stream
// ---------------------------------------------------------------------------

/// Immutable view-model for the stats cards shown on the Reminders page.
class RemindersStats {
  final int totalThisMonth;
  final DateTime nextSendDate;

  const RemindersStats({
    required this.totalThisMonth,
    required this.nextSendDate,
  });
}

@riverpod
RemindersStats remindersStats(Ref ref, String providerId) {
  final logs =
      ref.watch(communicationLogsProvider(providerId)).valueOrNull ?? [];
  final now = DateTime.now();

  final totalThisMonth =
      logs
          .where(
            (l) =>
                l.status == 'sent' &&
                l.sentAt.year == now.year &&
                l.sentAt.month == now.month,
          )
          .length;

  // Next 1st: always the first day of the next month (since we are always on or past day 1).
  final DateTime nextSend = DateTime(now.year, now.month + 1, 1);

  return RemindersStats(totalThisMonth: totalThisMonth, nextSendDate: nextSend);
}
