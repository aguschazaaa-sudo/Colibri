import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/vacation_period.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:cobrador/presentation/providers/use_case_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' hide Provider;

part 'provider_profile_provider.g.dart';

@riverpod
class ProviderProfile extends _$ProviderProfile {
  @override
  Stream<Provider?> build(String providerId) {
    final repository = ref.watch(providerRepositoryProvider);
    return repository.watchProvider(providerId);
  }

  Future<void> updateProfile(Provider provider) async {
    final useCase = ref.read(updateProviderProfileUseCaseProvider);
    final result = await useCase.execute(provider);

    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }

  Future<void> addNonWorkingDay(String providerId, String day) async {
    final repository = ref.read(providerRepositoryProvider);
    final result = await repository.addNonWorkingDay(providerId, day);
    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }

  Future<void> removeNonWorkingDay(String providerId, String day) async {
    final repository = ref.read(providerRepositoryProvider);
    final result = await repository.removeNonWorkingDay(providerId, day);
    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }

  Future<void> addVacationPeriod(
    String providerId,
    DateTime start,
    DateTime end,
  ) async {
    final repository = ref.read(providerRepositoryProvider);
    final period = VacationPeriod(startDate: start, endDate: end);
    final result = await repository.addVacationPeriod(providerId, period);
    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }

  Future<void> removeVacationPeriod(
    String providerId,
    VacationPeriod period,
  ) async {
    final repository = ref.read(providerRepositoryProvider);
    final result = await repository.removeVacationPeriod(providerId, period);
    result.fold((failure) => throw Exception(failure.message), (_) => null);
  }
}
