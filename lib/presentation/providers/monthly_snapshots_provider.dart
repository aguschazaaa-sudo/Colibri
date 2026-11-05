import 'package:cobrador/domain/monthly_snapshot.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'monthly_snapshots_provider.g.dart';

/// Watches the last 12 monthly revenue snapshots for [providerId].
///
/// Emits an ordered list from most recent to oldest.
/// Returns an empty list when no snapshots exist yet (first month of use).
@riverpod
Stream<List<MonthlySnapshot>> monthlySnapshots(
  Ref ref, {
  required String providerId,
}) =>
    ref
        .watch(providerRepositoryProvider)
        .watchMonthlySnapshots(providerId, limit: 12);
