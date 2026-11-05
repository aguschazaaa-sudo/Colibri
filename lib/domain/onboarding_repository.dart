import 'package:fpdart/fpdart.dart';

abstract class OnboardingRepository {
  Future<bool> hasSeenOnboarding();

  Future<Unit> markOnboardingSeen();
}
