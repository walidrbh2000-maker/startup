// lib/providers/onboarding_controller.dart
//
// Tracks whether the user has completed the onboarding slides.
//
// State: bool — true = onboarding done, false = not done.
// keepAlive: true — must survive navigation (the router reads it on every redirect).
//
// Initialization is asynchronous. The router waits until [isLoaded] is true
// (via the splash controller) before reading [onboardingDone].

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────

class OnboardingController extends StateNotifier<bool> {
  bool _isLoaded = false;

  OnboardingController() : super(false) {
    _load();
  }

  bool get isLoaded => _isLoaded;

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done  = prefs.getBool(PrefKeys.onboardingDone) ?? false;
      if (mounted) state = done;
    } catch (e) {
      AppLogger.warning('OnboardingController: load error — $e');
    } finally {
      _isLoaded = true;
    }
  }

  // ── Mark done ──────────────────────────────────────────────────────────────

  /// Called when the user taps "Get started" at the end of onboarding.
  /// Updates state synchronously for immediate router response.
  Future<void> markDone() async {
    if (state) return;
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.onboardingDone, true);
    } catch (e) {
      AppLogger.warning('OnboardingController: persist error — $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider — keepAlive so the router can read it without re-initializing.
// ─────────────────────────────────────────────────────────────────────────────

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
  return OnboardingController();
});

/// Convenience provider: true when onboarding has been completed.
final onboardingDoneProvider = Provider<bool>((ref) {
  return ref.watch(onboardingControllerProvider);
});
