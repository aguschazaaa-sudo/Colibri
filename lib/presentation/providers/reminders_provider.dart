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
            (l) => l.sentAt.year == now.year && l.sentAt.month == now.month,
          )
          .length;

  // Next 28th: if today is already on or past 28, roll to next month
  final DateTime nextSend;
  if (now.day < 28) {
    nextSend = DateTime(now.year, now.month, 28);
  } else {
    nextSend = DateTime(now.year, now.month + 1, 28);
  }

  return RemindersStats(totalThisMonth: totalThisMonth, nextSendDate: nextSend);
}
