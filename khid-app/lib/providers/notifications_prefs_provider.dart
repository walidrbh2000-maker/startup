// lib/providers/notifications_prefs_provider.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';
import 'app_lifecycle_provider.dart';

// ============================================================================
// NOTIFICATION PREFERENCES STATE
// ============================================================================

class NotificationPrefsState {
  final bool isLoading;

  // If OS-level notification permission is blocked, all in-app toggles are
  // silently ineffective. The screen reads this field to show a warning banner.
  // Sourced from FirebaseMessaging.getNotificationSettings() in _load();
  // call refreshSystemPermission() on app-resume to keep it current.
  final bool systemPermissionDenied;

  final bool newRequests;
  final bool bidReceived;
  final bool chatMessages;
  final bool promotions;

  const NotificationPrefsState({
    this.isLoading              = true,
    this.systemPermissionDenied = false,
    this.newRequests            = true,
    this.bidReceived            = true,
    this.chatMessages           = true,
    this.promotions             = false,
  });

  NotificationPrefsState copyWith({
    bool? isLoading,
    bool? systemPermissionDenied,
    bool? newRequests,
    bool? bidReceived,
    bool? chatMessages,
    bool? promotions,
  }) {
    return NotificationPrefsState(
      isLoading:              isLoading              ?? this.isLoading,
      systemPermissionDenied: systemPermissionDenied ?? this.systemPermissionDenied,
      newRequests:            newRequests            ?? this.newRequests,
      bidReceived:            bidReceived            ?? this.bidReceived,
      chatMessages:           chatMessages           ?? this.chatMessages,
      promotions:             promotions             ?? this.promotions,
    );
  }
}

// ============================================================================
// PREFERENCE KEYS
// ============================================================================

// Keys live in PrefKeys (constants.dart) — shared with the push coordinator,
// which enforces these toggles on foreground notification display.
abstract class _Keys {
  static const newRequests  = PrefKeys.notifNewRequests;
  static const bidReceived  = PrefKeys.notifBidReceived;
  static const chatMessages = PrefKeys.notifChatMessages;
  static const promotions   = PrefKeys.notifPromotions;
}

// ============================================================================
// NOTIFICATIONS PREFS NOTIFIER
// ============================================================================

class NotificationPrefsNotifier
    extends StateNotifier<NotificationPrefsState> {
  NotificationPrefsNotifier() : super(const NotificationPrefsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final systemDenied = await _isSystemDenied();

      if (mounted) {
        state = NotificationPrefsState(
          isLoading:              false,
          systemPermissionDenied: systemDenied,
          newRequests:   prefs.getBool(_Keys.newRequests)  ?? true,
          bidReceived:   prefs.getBool(_Keys.bidReceived)  ?? true,
          chatMessages:  prefs.getBool(_Keys.chatMessages) ?? true,
          promotions:    prefs.getBool(_Keys.promotions)   ?? false,
        );
      }
    } catch (e) {
      AppLogger.error('NotificationPrefsNotifier._load', e);
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  /// Re-checks the OS-level notification permission. Call this when the app
  /// resumes (e.g. after the user returns from system settings) so the warning
  /// banner reflects the current state without a full reload.
  Future<void> refreshSystemPermission() async {
    final systemDenied = await _isSystemDenied();
    if (mounted && systemDenied != state.systemPermissionDenied) {
      state = state.copyWith(systemPermissionDenied: systemDenied);
    }
  }

  /// True when the OS has explicitly blocked notifications. `notDetermined`
  /// (not yet asked) and `provisional`/`authorized` are NOT treated as denied.
  /// Any platform error degrades to `false` — we never falsely warn the user.
  Future<bool> _isSystemDenied() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.denied;
    } catch (e) {
      AppLogger.error('NotificationPrefsNotifier._isSystemDenied', e);
      return false;
    }
  }

  Future<void> setNewRequests(bool v) =>
      _set(_Keys.newRequests, v, (s) => s.copyWith(newRequests: v));

  Future<void> setBidReceived(bool v) =>
      _set(_Keys.bidReceived, v, (s) => s.copyWith(bidReceived: v));

  Future<void> setChatMessages(bool v) =>
      _set(_Keys.chatMessages, v, (s) => s.copyWith(chatMessages: v));

  Future<void> setPromotions(bool v) =>
      _set(_Keys.promotions, v, (s) => s.copyWith(promotions: v));

  Future<void> _set(
    String key,
    bool   value,
    NotificationPrefsState Function(NotificationPrefsState) updater,
  ) async {
    // Optimistic update — UI reflects change immediately.
    if (mounted) state = updater(state);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      AppLogger.error('NotificationPrefsNotifier._set($key)', e);
    }
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final notificationPrefsProvider = StateNotifierProvider.autoDispose<
    NotificationPrefsNotifier,
    NotificationPrefsState>(
  (ref) {
    final notifier = NotificationPrefsNotifier();
    // Coming back from OS settings fires a resume — re-check the system
    // permission so the warning banner clears without reopening the screen.
    ref.listen<AppLifecycleStateEnum>(appLifecycleProvider, (prev, next) {
      if (next == AppLifecycleStateEnum.resumed &&
          prev != AppLifecycleStateEnum.resumed) {
        notifier.refreshSystemPermission();
      }
    });
    return notifier;
  },
);
