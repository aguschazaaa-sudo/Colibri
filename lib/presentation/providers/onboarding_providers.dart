import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cobrador/domain/onboarding_repository.dart';
import 'package:cobrador/data/repositories/onboarding_repository_impl.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl();
});

class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repo = ref.read(onboardingRepositoryProvider);
    return repo.hasSeenOnboarding();
  }

  Future<void> complete() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.markOnboardingSeen();
    state = const AsyncData(true);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(
      OnboardingController.new,
    );
