// lib/providers/splash_controller.dart
//
// ROLE RESOLUTION — TWO-TIER STRATEGY:
//
//   Tier 1 (preferred): GET /users/:uid from the backend.
//     → Authoritative, reflects latest server state.
//     → Persists result to SharedPreferences for Tier 2.
//
//   Tier 2 (fallback): read `accountRole` from SharedPreferences.
//     → Used when the backend is unreachable (no server yet, offline, timeout).
//     → Written by ProfileSetupController after a successful submit, and by
//       Tier 1 after every successful server read.
//     → If the pref is absent it means the user has never completed profile
//       setup → cachedUserRoleProvider stays UserRole.unknown.
//
// ROUTER CONTRACT:
//   The router's splash redirect reads cachedUserRoleProvider:
//     unknown  → AppRoutes.roleSelection   (profile not set up)
//     client   → AppRoutes.home
//     worker   → AppRoutes.home
//
//   This eliminates the "failed submit → works on reopen" symptom: a user
//   who pressed submit while the server was down has no prefs entry, so
//   cachedRole stays unknown and the router sends them back to role-selection
//   rather than straight to /home.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_providers.dart';
import '../providers/onboarding_controller.dart';
import '../services/api_service.dart';
import '../providers/user_role_provider.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'core_providers.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum SplashPhase { initializing, animating, ready, error }
enum SplashErrorType { none, noInternet, serverError, timeout, unknown }

// ── State ──────────────────────────────────────────────────────────────────

class SplashState {
  final SplashPhase     phase;
  final SplashErrorType errorType;

  const SplashState({
    this.phase     = SplashPhase.initializing,
    this.errorType = SplashErrorType.none,
  });

  bool get canRetry => phase == SplashPhase.error;

  SplashState copyWith({SplashPhase? phase, SplashErrorType? errorType}) {
    return SplashState(
      phase:     phase     ?? this.phase,
      errorType: errorType ?? this.errorType,
    );
  }
}

// ── Controller ─────────────────────────────────────────────────────────────

class SplashController extends StateNotifier<SplashState> {
  final Ref _ref;

  bool _isAnimationComplete  = false;
  bool _isAuthChecked        = false;
  bool _isMinDurationElapsed = false;
  bool _isInitializing       = false;

  Timer? _minDurationTimer;

  static const Duration _kMinSplashDuration  = Duration(seconds: 3);
  static const Duration _globalInitTimeout   = Duration(seconds: 15);
  static const Duration _kRoleResolveTimeout = Duration(seconds: 5);
  static const Duration _kAuthStateTimeout   = Duration(seconds: 10);

  SplashController(this._ref) : super(const SplashState());

  // ── Initialization ─────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _isAuthChecked        = false;
      _isMinDurationElapsed = false;
      _minDurationTimer?.cancel();

      if (!mounted) return;
      state = const SplashState(phase: SplashPhase.initializing);

      _armMinDurationTimer();

      // No artificial delay here — _kMinSplashDuration already guarantees the
      // minimum on-screen time; init should finish as fast as it can.
      await Future.wait([
        _waitForAuthState(),
        _waitForOnboarding(),
      ]).timeout(
        _globalInitTimeout,
        onTimeout: () {
          AppLogger.warning('SplashController: global timeout');
          throw TimeoutException('Splash init timeout', _globalInitTimeout);
        },
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _resolveAndCacheRole(currentUser.uid);
      }

      _isAuthChecked = true;
      _updateState();
    } on TimeoutException {
      AppLogger.warning('SplashController: timeout');
      if (!mounted) return;
      _isAuthChecked = true;
      state = state.copyWith(
        phase:     SplashPhase.error,
        errorType: SplashErrorType.timeout,
      );
    } on FirebaseException catch (e) {
      AppLogger.error('SplashController (Firebase)', e);
      if (!mounted) return;
      _isAuthChecked = true;
      state = state.copyWith(
        phase:     SplashPhase.error,
        errorType: _mapFirebaseError(e),
      );
    } catch (e, stack) {
      AppLogger.error('SplashController', '$e\n$stack');
      if (!mounted) return;
      _isAuthChecked = true;
      state = state.copyWith(
        phase:     SplashPhase.error,
        errorType: SplashErrorType.unknown,
      );
    } finally {
      _isInitializing = false;
    }
  }

  void onAnimationComplete() {
    _isAnimationComplete = true;
    _updateState();
  }

  Future<void> retry() => initialize();

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _waitForAuthState() async {
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(_kAuthStateTimeout, onTimeout: () => null);
    } catch (e) {
      AppLogger.warning('SplashController: auth state timeout — continuing');
    }
  }

  Future<void> _waitForOnboarding() async {
    const maxWait  = Duration(seconds: 2);
    const interval = Duration(milliseconds: 50);
    final start    = DateTime.now();

    final ctrl = _ref.read(onboardingControllerProvider.notifier);
    while (!ctrl.isLoaded) {
      if (DateTime.now().difference(start) > maxWait) break;
      await Future.delayed(interval);
    }
  }

  void _armMinDurationTimer() {
    _minDurationTimer = Timer(_kMinSplashDuration, () {
      if (!mounted) return;
      _isMinDurationElapsed = true;
      _updateState();
    });
  }

  void _updateState() {
    if (!mounted) return;
    if (state.phase == SplashPhase.error) return;

    if (_isAnimationComplete && _isAuthChecked && _isMinDurationElapsed) {
      state = state.copyWith(phase: SplashPhase.ready);
      _ref.read(appInitializedProvider.notifier).state = true;
      _ref.read(authRedirectNotifierProvider).notifyAuthReady();
    } else if (_isAuthChecked && !_isAnimationComplete) {
      state = state.copyWith(phase: SplashPhase.animating);
    }
  }

  // ── Role resolution — two-tier ────────────────────────────────────────────

  /// Tier 1: resolve role from the backend.
  /// Falls back to Tier 2 (SharedPreferences) on any network/server error.
  ///
  /// On success, persists the resolved role to SharedPreferences so that
  /// Tier 2 is always up-to-date for the next offline start.
  ///
  /// IMPORTANT: if neither tier can resolve the role, cachedUserRoleProvider
  /// stays UserRole.unknown.  The router interprets unknown-after-splash as
  /// "profile not set up" and redirects to AppRoutes.roleSelection.
  Future<void> _resolveAndCacheRole(String uid) async {
    // ── Tier 1: backend ─────────────────────────────────────────────────────
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);

      final userDoc = await firestoreService
          .getUser(uid)
          .timeout(_kRoleResolveTimeout, onTimeout: () => null);

      if (userDoc != null) {
        final role = userDoc.isWorker ? UserRole.worker : UserRole.client;

        _setCachedRole(role);

        // Keep prefs in sync with latest server state.
        await _writeRoleToPrefs(role);
        AppLogger.info('SplashController: role=$role from server uid=$uid');
        return;
      }

      // Server returned null document — fall through to Tier 2.
      AppLogger.warning('SplashController: getUser returned null for uid=$uid');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppLogger.error('SplashController: PERMISSION_DENIED uid=$uid', e);
        rethrow;
      }
      AppLogger.warning(
        'SplashController: server error (${e.code}) — trying prefs fallback',
      );
    } on ApiServiceException catch (e) {
      // Account-PIN gate (cold start on an untrusted device): every backend
      // call is rejected until verify-pin succeeds. Raise the gate — the
      // router parks the user on /pin-verify. Do NOT fall through to prefs:
      // a cached role would route to a home where every request 403s.
      if (e.code == 'PIN_REQUIRED') {
        _ref.read(pinGateProvider.notifier).state = true;
        AppLogger.info('SplashController: PIN required for uid=$uid');
        return;
      }
      // Document-approval gate (cold start while docs await admin review):
      // same reasoning — park on /pending-approval, don't use cached role.
      if (e.code == 'APPROVAL_PENDING') {
        _ref.read(approvalGateProvider.notifier).state = true;
        AppLogger.info('SplashController: approval pending for uid=$uid');
        return;
      }
      AppLogger.warning(
        'SplashController: backend unreachable — trying prefs fallback ($e)',
      );
    } catch (e) {
      AppLogger.warning(
        'SplashController: backend unreachable — trying prefs fallback ($e)',
      );
    }

    // ── Tier 2: SharedPreferences fallback ──────────────────────────────────
    await _resolveRoleFromPrefs(uid);
  }

  /// Tier 2: read the role that was persisted by ProfileSetupController
  /// (on successful submit) or by a previous successful Tier-1 resolution.
  ///
  /// If no entry is found, the cachedUserRoleProvider is left as
  /// UserRole.unknown, which causes the router to redirect to roleSelection.
  Future<void> _resolveRoleFromPrefs(String uid) async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final saved  = prefs.getString(PrefKeys.accountRole);

      if (saved == null) {
        // No pref entry → user never completed profile setup successfully.
        // Leave cachedRole as UserRole.unknown.
        AppLogger.info(
          'SplashController: no role pref for uid=$uid → unknown → roleSelection',
        );
        return;
      }

      final role = saved == UserType.worker ? UserRole.worker : UserRole.client;
      _setCachedRole(role);
      AppLogger.info('SplashController: role=$role from prefs uid=$uid');
    } catch (e) {
      AppLogger.error('SplashController._resolveRoleFromPrefs', e);
      // Leave cachedRole as unknown — router sends to roleSelection.
    }
  }

  /// Writes `accountRole` pref — single helper to avoid duplication.
  Future<void> _writeRoleToPrefs(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PrefKeys.accountRole,
        role == UserRole.worker ? UserType.worker : UserType.user,
      );
    } catch (e) {
      AppLogger.warning('SplashController._writeRoleToPrefs failed: $e');
    }
  }

  /// Thin wrapper so call sites don't have to read the notifier every time.
  void _setCachedRole(UserRole role) {
    setCachedUserRole(
      _ref.read(cachedUserRoleProvider.notifier),
      role,
    );
  }

  SplashErrorType _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'network-request-failed': return SplashErrorType.noInternet;
      case 'internal-error':
      case 'unavailable':
      case 'permission-denied':      return SplashErrorType.serverError;
      case 'deadline-exceeded':      return SplashErrorType.timeout;
      default:                       return SplashErrorType.unknown;
    }
  }

  @override
  void dispose() {
    _minDurationTimer?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final splashControllerProvider =
    StateNotifierProvider.autoDispose<SplashController, SplashState>(
  (ref) => SplashController(ref),
);
