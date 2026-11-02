import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  OnboardingStorage._();
  static final OnboardingStorage instance = OnboardingStorage._();

  static const _key = 'onboarding_complete';

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
