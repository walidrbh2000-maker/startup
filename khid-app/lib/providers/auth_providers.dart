// lib/providers/auth_providers.dart
//
// App-level auth providers.
//
// MIGRATION NOTE:
//   - Removed appInitializedProvider (now in splash_controller, guards router)
//   - Kept firebaseAuthStreamProvider as the single source of truth for UID.
//   - LoginController / RegisterController removed — see AuthController.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

// ── Auth redirect notifier ─────────────────────────────────────────────────
//
// Used by the router as part of its refreshListenable composite.
// Notified after sign-in and sign-out to trigger a redirect evaluation.

class AuthRedirectNotifier extends ChangeNotifier {
  void notifyAuthReady()  => notifyListeners();
  void notifySignedOut()  => notifyListeners();
}

final authRedirectNotifierProvider =
    Provider<AuthRedirectNotifier>((ref) => AuthRedirectNotifier());

// ── Account-PIN gate ───────────────────────────────────────────────────────
//
// True when the backend answered PIN_REQUIRED for this device (account has an
// anti-SIM-recycling PIN and this install is not yet trusted). The router
// redirects every in-app location to /pin-verify while this is set.
// Writers: AuthController flow (phone_auth listener), SplashController
// (PIN_REQUIRED on role resolution), PinVerifyScreen (false on success).

final pinGateProvider = StateProvider<bool>((ref) => false);

// ── Document-approval gate ─────────────────────────────────────────────────
//
// Set when the backend answers APPROVAL_PENDING (the account submitted worker/
// business verification documents and an admin has not yet approved). The
// router redirects every in-app location to /pending-approval while this is
// set. The pending screen polls /auth/check and clears it once the admin
// approves. Writers: ApiService onApprovalPending hook, SplashController,
// ProfileSetupController (on submit with docs), PendingApprovalScreen (clears).
final approvalGateProvider = StateProvider<bool>((ref) => false);

// ── App initialized flag ───────────────────────────────────────────────────
//
// Set to true by SplashController when Firebase auth + onboarding state
// are both resolved. The router uses this to stay on /splash until ready.

final appInitializedProvider = StateProvider<bool>((ref) => false);

// ── Firebase auth stream ───────────────────────────────────────────────────
//
// Single source of truth for the authenticated Firebase user.
// Only emits on actual UID changes — never on isLoading flips.

final firebaseAuthStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ── Computed auth providers ────────────────────────────────────────────────

/// Current Firebase user. Falls back to FirebaseAuth.instance.currentUser
/// during the loading frame to prevent a null-flash on first render.
final currentUserProvider = Provider<User?>((ref) {
  final stream = ref.watch(firebaseAuthStreamProvider);
  return stream.valueOrNull ?? FirebaseAuth.instance.currentUser;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

/// True when the session is an anonymous guest (browsing without an account).
/// Account-gated actions call requireAuth() which reads this.
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAnonymous ?? false;
});

/// True only while the auth stream has not yet emitted its first value.
/// This is NOT true during the phone auth flow — use AuthController.isLoading
/// for that.
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(firebaseAuthStreamProvider).isLoading;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
