import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding completion status
class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Check if onboarding has been completed
  static Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      // If there's an error, assume onboarding is not completed
      return false;
    }
  }

  /// Mark onboarding as completed
  static Future<void> setOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } catch (e) {
      // Silently handle errors
      print('Error setting onboarding complete: $e');
    }
  }

  /// Reset onboarding status (useful for testing)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
    } catch (e) {
      // Silently handle errors
      print('Error resetting onboarding: $e');
    }
  }
}
