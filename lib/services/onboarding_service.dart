import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding state
class OnboardingService {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
  }
  
  /// Reset onboarding status (for testing purposes)
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, false);
  }
} 