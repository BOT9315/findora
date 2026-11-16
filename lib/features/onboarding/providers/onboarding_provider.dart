import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _checkStatus();
  }

  static const String _key = 'onboarding_completed';

  Future<void> _checkStatus() async {
    try {
      final val = await AppDatabase.instance.getSetting(_key);
      state = val == 'true';
    } catch (_) {
      state = false;
    }
  }

  Future<void> completeOnboarding() async {
    state = true;
    try {
      await AppDatabase.instance.setSetting(_key, 'true');
    } catch (_) {}
  }

  Future<void> resetOnboarding() async {
    state = false;
    try {
      await AppDatabase.instance.removeSetting(_key);
    } catch (_) {}
  }
}
