import 'package:cobrador/domain/dashboard_report.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.g.dart';

@riverpod
Stream<DashboardReport> dashboardReport(Ref ref, String providerId) {
  final repository = ref.watch(providerRepositoryProvider);
  return repository.watchDashboardReport(providerId);
}
