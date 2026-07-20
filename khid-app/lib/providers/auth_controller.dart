// lib/providers/auth_controller.dart
//
// StateNotifier that drives the entire phone authentication flow.
//
// Flow:
//   sendOtp()                → sendingOtp → otpSent
//   verifyOtp(code)          → verifying  → success / error
//   handleInstantVerification → verifying  → success
//   resendOtp()              → sendingOtp → otpSent (with resendToken)
//
// Post-success navigation is handled by the router via firebaseAuthStreamProvider,
// NOT by this controller. The controller sets status: success and stops there.
// The isNewUser flag tells the router which screen to go to next.
//
// Design notes:
// - verificationId is stored in state so it survives widget rebuilds and
//   hot reload.
// - The 90-second resend cooldown is managed by a Timer here, not in the UI.
// - Network retry for verifyPhoneNumber (x2 on network-request-failed).
// - signInWithCredential has a 15-second timeout.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_state.dart';
import '../models/user_check_result.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/analytics_service.dart';
import '../services/firebase_auth_service.dart';
import '../utils/form_validators.dart';
import 'core_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────

class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuthService _firebase;
  final ApiService          _api;
  final AuthService         _authService;
  final AnalyticsService    _analytics;

  static const Duration _signinTimeout   = Duration(seconds: 15);
  static const int      _resendCooldownS = 90;
  static const int      _maxRetries      = 2;

  Timer? _resendTimer;

  AuthController({
    required FirebaseAuthService firebaseAuthService,
    required ApiService          api,
    required AuthService         authService,
    required AnalyticsService    analytics,
  })  : _firebase    = firebaseAuthService,
        _api         = api,
        _authService = authService,
        _analytics   = analytics,
        super(const AuthState());

  // ══════════════════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════════════════

  /// Step 1 — send OTP to [rawPhone] (any Algerian format).
  Future<void> sendOtp(String rawPhone) async {
    if (state.status == AuthStatus.sendingOtp) return;

    final e164 = FormValidators.toE164Algeria(rawPhone);
    if (!FormValidators.isValidE164(e164)) {
      state = state.copyWith(
        status:   AuthStatus.error,
        errorKey: 'errors.phone_invalid_format',
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      phone:  e164,
      clearError: true,
    );

    await _sendVerificationWithRetry(e164, isResend: false);
  }

  /// Step 2a — called when Firebase triggers instant verification (Android SIM).
  ///
  /// The widget MUST guard against calling this on a disposed widget:
  /// ```dart
  ///   verificationCompleted: (credential) {
  ///     if (!mounted) return;
  ///     ref.read(authControllerProvider.notifier).handleInstantVerification(credential);
  ///   },
  /// ```
  Future<void> handleInstantVerification(PhoneAuthCredential credential) async {
    if (!mounted) return;
    _log('Instant verification triggered');
    state = state.copyWith(
      status:            AuthStatus.verifying,
      isInstantVerified: true,
      clearError:        true,
    );
    await _signInWithCredential(credential);
  }

  /// Step 2b — manual OTP entry after codeSent.
  Future<void> verifyOtp(String code) async {
    if (state.status == AuthStatus.verifying) return;
    if (code.length != 6) {
      state = state.copyWith(status: AuthStatus.error, errorKey: 'errors.otp_invalid');
      return;
    }
    final verificationId = state.verificationId;
    if (verificationId == null) {
      state = state.copyWith(status: AuthStatus.error, errorKey: 'errors.otp_expired');
      return;
    }

    state = state.copyWith(status: AuthStatus.verifying, clearError: true);

    final credential = _firebase.buildCredential(
      verificationId: verificationId,
      smsCode:        code,
    );
    await _signInWithCredential(credential);
  }

  /// Resend OTP using the stored [resendToken] (avoids re-billing the session).
  Future<void> resendOtp() async {
    if (!state.canResend) return;
    state = state.copyWith(status: AuthStatus.sendingOtp, clearError: true);
    await _sendVerificationWithRetry(state.phone, isResend: true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _sendVerificationWithRetry(String e164, {required bool isResend}) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _firebase.sendVerificationCode(
          phone:               e164,
          forceResendingToken: isResend ? state.resendToken : null,
          onVerificationCompleted: (credential) {
            if (!mounted) return;
            handleInstantVerification(credential);
          },
          onVerificationFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            _log('verificationFailed: ${e.code}');
            final isQuota = e.code == 'quota-exceeded';
            state = state.copyWith(
              status:   isQuota ? AuthStatus.quotaExceeded : AuthStatus.error,
              errorKey: FirebaseAuthService.mapFirebaseError(e.code),
            );
          },
          onCodeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            _log('codeSent → verificationId stored in state');
            _startResendTimer();
            state = state.copyWith(
              status:         AuthStatus.otpSent,
              verificationId: verificationId,
              resendToken:    resendToken ?? state.resendToken,
              clearError:     true,
            );
          },
          onCodeAutoRetrievalTimeout: (String verificationId) {
            if (!mounted) return;
            _log('autoRetrievalTimeout');
            // Update verificationId but keep otpSent status — user can still enter manually.
            if (state.status == AuthStatus.otpSent) {
              state = state.copyWith(verificationId: verificationId);
            }
          },
        );
        return; // success — exit retry loop
      } on FirebaseAuthException catch (e) {
        final isRetriable = e.code == 'network-request-failed' && attempt < _maxRetries;
        if (isRetriable) {
          _log('Network error (attempt $attempt/$_maxRetries), retrying...');
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        if (!mounted) return;
        state = state.copyWith(
          status:   AuthStatus.error,
          errorKey: FirebaseAuthService.mapFirebaseError(e.code),
        );
        return;
      } catch (e) {
        if (!mounted) return;
        _logError('sendVerification', e);
        state = state.copyWith(status: AuthStatus.error, errorKey: 'errors.auth_generic');
        return;
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await _firebase
          .signInWithCredential(credential)
          .timeout(_signinTimeout);

      final user = result.user;
      if (user == null) {
        if (!mounted) return;
        state = state.copyWith(status: AuthStatus.error, errorKey: 'errors.auth_generic');
        return;
      }

      // FIX Bug 2 & 3: احدد أولاً هل هو مستخدم جديد قبل أي auto-provisioning.
      //
      // المشكلة السابقة:
      //   ensureBackendProfile كانت تُستدعى fire-and-forget قبل _checkIsNewUser.
      //   بما أن GET /users/:id يستدعي ensureExists() من الـ backend، ينشئ
      //   stub من نوع client قبل أن يصل _checkIsNewUser — فيُعيد isNewUser=false
      //   وتذهب للـ home بدلاً من role-selection.
      //
      // الحل:
      //   1. استدعِ _checkIsNewUser أولاً (بدون أي stub موجود).
      //   2. استدعِ ensureBackendProfile فقط للمستخدمين الموجودين (isNew=false).
      //      المستخدمون الجدد سيُنشئون ملفهم عبر شاشات الإعداد.

      final check = await _checkUser(user.uid);
      final isNew = check.isNewUser;

      // فقط للمستخدمين العائدين الذين قد يكون ملفهم في MongoDB اختفى —
      // وليس عندما يكون PIN مطلوباً (كل نداء API سيُرفض بـ PIN_REQUIRED
      // حتى ينجح verify-pin من هذا الجهاز) ولا عندما تكون المستندات قيد
      // المراجعة (APPROVAL_PENDING بنفس المنطق).
      if (!isNew && !check.pinRequired && !check.needsApproval) {
        _authService.ensureBackendProfile(user);
      }

      // Analytics: restores the auth-funnel event that lived in the (removed)
      // LoginController. Phone is now the only sign-in provider.
      _analytics.logUserSignedIn(provider: 'phone');

      if (!mounted) return;
      state = state.copyWith(
        status:           AuthStatus.success,
        isNewUser:        isNew,
        pinRequired:      check.pinRequired,
        approvalRequired: check.needsApproval,
        clearError:       true,
      );
      _log('Sign-in success uid=${user.uid} isNewUser=$isNew pinRequired=${check.pinRequired}');
    } on TimeoutException {
      if (!mounted) return;
      state = state.copyWith(status: AuthStatus.error, errorKey: 'errors.network');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status:   AuthStatus.error,
        errorKey: FirebaseAuthService.mapFirebaseError(e.code),
      );
    } catch (e) {
      if (!mounted) return;
      _logError('signInWithCredential', e);
      state = state.copyWith(status: AuthStatus.error, errorKey: 'errors.auth_generic');
    }
  }

  /// Full backend check: new-user flag + account-PIN device gate status.
  Future<UserCheckResult> _checkUser(String uid) async {
    try {
      return await _api.checkAuthUser(uid);
    } catch (e) {
      _logError('_checkUser', e);
      // Default to new user on error — the setup screen will upsert safely.
      return UserCheckResult.newUser;
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    state = state.copyWith(resendCooldown: _resendCooldownS);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      final remaining = state.resendCooldown - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(resendCooldown: 0);
      } else {
        state = state.copyWith(resendCooldown: remaining);
      }
    });
  }

  void _log(String msg)               { if (kDebugMode) debugPrint('[AuthController] $msg'); }
  void _logError(String m, Object e)  { if (kDebugMode) debugPrint('[AuthController] ✗ $m: $e'); }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
//
// autoDispose — released when the auth screen leaves the stack.
// The auth state should not persist after successful sign-in.

final authControllerProvider =
    StateNotifierProvider.autoDispose<AuthController, AuthState>((ref) {
  return AuthController(
    firebaseAuthService: ref.read(firebaseAuthServiceProvider),
    api:                 ref.read(apiServiceProvider),
    authService:         ref.read(authServiceProvider),
    analytics:           ref.read(analyticsServiceProvider),
  );
});
