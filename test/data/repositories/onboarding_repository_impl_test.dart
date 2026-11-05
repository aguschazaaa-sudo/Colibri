import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cobrador/data/repositories/onboarding_repository_impl.dart';

void main() {
  group('OnboardingRepositoryImpl', () {
    late OnboardingRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = OnboardingRepositoryImpl();
    });

    test('should return false when no value is stored', () async {
      final result = await repository.hasSeenOnboarding();
      expect(result, false);
    });

    test('should return true after marking onboarding as seen', () async {
      await repository.markOnboardingSeen();
      final result = await repository.hasSeenOnboarding();
      expect(result, true);
    });
  });
}
