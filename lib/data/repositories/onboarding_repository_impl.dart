import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _key = 'onboarding_seen';

  Future<SharedPreferences> _prefs() {
    return SharedPreferences.getInstance();
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await _prefs();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<Unit> markOnboardingSeen() async {
    final prefs = await _prefs();
    await prefs.setBool(_key, true);
    return unit;
  }
}
