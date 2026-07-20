// lib/router/app_router.dart
//
// REDIRECT LOGIC SUMMARY:
//   1. App not initialized           → /splash
//   2. Onboarding not done           → /onboarding
//   3. Not logged in                 → /phone-auth  (deep-link saved)
//   4. Logged in, from splash:
//        role == unknown             → /role-selection  (profile not set up)
//        role == client|worker       → /home
//   5. Logged in, on auth screens    → /home  (or saved deep-link)
//   6. Worker-only path for client   → /home
//   7. /worker-home                  → /home  (normalize legacy route)
//
// WHY role==unknown → roleSelection (not home):
//   SplashController uses a two-tier strategy to resolve the role:
//     Tier 1 — backend GET /users/:uid
//     Tier 2 — SharedPreferences (written by ProfileSetupController on success)
//   If both tiers fail to find a role the pref is absent, meaning the user
//   authenticated with Firebase but never completed profile setup.  Sending
//   them to /home would show an app with no profile — routing them back to
//   /role-selection is always safe because the setup screens upsert the
//   document and work correctly for both new and returning users.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/auth/pin_verify_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
import '../screens/settings/account_pin_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/user_profile_screen.dart';
import '../screens/auth/worker_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/service_request/service_request_screen.dart';
import '../screens/service_request/bids_list_screen.dart';
import '../screens/service_request/request_tracking_screen.dart';
import '../screens/service_request/rating_screen.dart';
import '../screens/worker_jobs/worker_jobs_screen.dart';
import '../screens/worker_jobs/job_detail_screen.dart';
import '../screens/worker_jobs/submit_bid_screen.dart';
import '../screens/edit_profile/edit_profile_screen.dart';
import '../screens/worker_profile/worker_profile_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/notifications_inbox_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/help/help_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/core_providers.dart';
import '../providers/onboarding_controller.dart';
import '../providers/user_role_provider.dart';
import '../services/auth_service.dart';
import '../utils/composite_listenable.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../utils/logger.dart';

// ── Deep-link restoration ──────────────────────────────────────────────────

final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);

// ── Router provider ────────────────────────────────────────────────────────

final goRouterProvider = Provider<GoRouter>((ref) {
  final authService      = ref.read(authServiceProvider);
  final redirectNotifier = ref.read(authRedirectNotifierProvider);

  final userIdentityListenable = _UserIdentityListenable(authService);
  final listenable = CompositeListenable([
    userIdentityListenable,
    redirectNotifier,
  ]);

  // Mid-session PIN gating: a PIN change on another device untrusts this one
  // instantly (every response turns 403 PIN_REQUIRED). The ApiService hook
  // raises the gate; the listen below re-runs the redirect. Without this the
  // app shows generic errors until a cold restart.
  ref.read(apiServiceProvider).onPinRequired = () {
    final gate = ref.read(pinGateProvider.notifier);
    if (!gate.state) gate.state = true;
  };
  ref.listen<bool>(pinGateProvider, (prev, next) {
    if (prev != next) redirectNotifier.notifyAuthReady();
  });

  // Mid-session approval gating: identical mechanism for APPROVAL_PENDING —
  // an account whose documents await admin review is parked on the pending
  // screen the moment any call is gated.
  ref.read(apiServiceProvider).onApprovalPending = () {
    final gate = ref.read(approvalGateProvider.notifier);
    if (!gate.state) gate.state = true;
  };
  ref.listen<bool>(approvalGateProvider, (prev, next) {
    if (prev != next) redirectNotifier.notifyAuthReady();
  });

  ref.onDispose(() {
    userIdentityListenable.dispose();
    listenable.dispose();
  });

  // Matches /worker/<single segment> — the public worker profile viewer,
  // which is accessible to all authenticated users regardless of role.
  final _workerProfilePattern = RegExp(r'^/worker/[^/]+$');

  // Paths that must never be stored as pending deep links.
  const _authPaths = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.phoneAuth,
    AppRoutes.pinVerify,
    AppRoutes.pendingApproval,
    AppRoutes.roleSelection,
    AppRoutes.userProfileSetup,
    AppRoutes.workerProfileSetup,
  };

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: listenable,

    redirect: (context, state) {
      final appInitialized = ref.read(appInitializedProvider);
      if (!appInitialized) {
        return state.matchedLocation == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isLoggedIn  = authService.isLoggedIn;
      final isGuest     = authService.isGuest;
      final currentPath = state.matchedLocation;
      final cachedRole  = ref.read(cachedUserRoleProvider);
      final onboardingDone = ref.read(onboardingDoneProvider);

      // ── 0. Account-PIN gate ──────────────────────────────────────────────
      // Backend rejects every call with PIN_REQUIRED until this device passes
      // verify-pin — park the user on the PIN screen, nothing else will load.
      final pinGate = ref.read(pinGateProvider);
      if (pinGate && isLoggedIn) {
        return currentPath == AppRoutes.pinVerify ? null : AppRoutes.pinVerify;
      }
      if (!pinGate && currentPath == AppRoutes.pinVerify) {
        return AppRoutes.splash;
      }

      // ── 0bis. Document-approval gate ─────────────────────────────────────
      // Backend rejects every call with APPROVAL_PENDING until an admin
      // approves the submitted documents — park the user on the pending
      // screen. The setup screens stay reachable: a rejected account
      // resubmits its corrected documents through them (POST /users and the
      // document upload endpoint are gate-exempt server-side).
      final approvalGate = ref.read(approvalGateProvider);
      final isOnApprovalFlow = currentPath == AppRoutes.pendingApproval
          || currentPath == AppRoutes.userProfileSetup
          || currentPath == AppRoutes.workerProfileSetup;
      if (approvalGate && isLoggedIn && !isOnApprovalFlow) {
        return AppRoutes.pendingApproval;
      }
      if (!approvalGate && currentPath == AppRoutes.pendingApproval) {
        return AppRoutes.splash;
      }

      final isOnSplash      = currentPath == AppRoutes.splash;
      final isOnOnboarding  = currentPath == AppRoutes.onboarding;
      final isOnAuth        = currentPath == AppRoutes.phoneAuth;
      final isOnSetup       = currentPath == AppRoutes.roleSelection
                           || currentPath == AppRoutes.userProfileSetup
                           || currentPath == AppRoutes.workerProfileSetup;
      final isOnWorkerHome  = currentPath == AppRoutes.workerHome;
      final isOnWorkerRoute = currentPath.startsWith('/worker');

      AppLogger.debug(
        'Redirect: path=$currentPath loggedIn=$isLoggedIn '
        'onboarding=$onboardingDone role=$cachedRole',
      );

      // ── 1. Splash → resolve navigation target ────────────────────────────
      if (isOnSplash) {
        if (!onboardingDone)             return AppRoutes.onboarding;
        if (!isLoggedIn)                 return AppRoutes.phoneAuth;
        // Guests have no profile/role — go straight to the browsable home.
        if (isGuest)                     return AppRoutes.home;

        // Role resolved by SplashController using the two-tier strategy:
        //   Tier 1 → backend   Tier 2 → SharedPreferences
        // unknown means neither tier found a role → user has no profile yet.
        if (cachedRole == UserRole.unknown) return AppRoutes.roleSelection;

        // Restore a deep link parked during splash (cold-start notification
        // tap) — same role guard as the post-sign-in restore below.
        final splashPendingLink = ref.read(pendingDeepLinkProvider.notifier).state;
        if (splashPendingLink != null) {
          ref.read(pendingDeepLinkProvider.notifier).state = null;
          final isWorkerOnlyPath = splashPendingLink.startsWith('/worker') &&
              !_workerProfilePattern.hasMatch(splashPendingLink);
          if (!(isWorkerOnlyPath && cachedRole == UserRole.client)) {
            return splashPendingLink;
          }
        }

        return AppRoutes.home;
      }

      // ── 2. Onboarding ────────────────────────────────────────────────────
      if (isOnOnboarding) return null;

      // ── 3. Unauthenticated access ────────────────────────────────────────
      if (!isLoggedIn && !isOnAuth && !isOnSetup) {
        if (!_authPaths.contains(currentPath)) {
          ref.read(pendingDeepLinkProvider.notifier).state = currentPath;
        }
        return AppRoutes.phoneAuth;
      }

      // ── 4. Post sign-in: restore deep link or go home ────────────────────
      if (isLoggedIn && (isOnAuth || isOnSplash)) {
        // Guest just tapped "continue as guest" → into the app.
        if (isGuest) return AppRoutes.home;
        // Still resolving role — wait.
        if (cachedRole == UserRole.unknown) return null;

        final pendingLink = ref.read(pendingDeepLinkProvider.notifier).state;
        if (pendingLink != null) {
          ref.read(pendingDeepLinkProvider.notifier).state = null;

          final isWorkerOnlyPath = pendingLink.startsWith('/worker') &&
              !_workerProfilePattern.hasMatch(pendingLink);

          if (isWorkerOnlyPath && cachedRole == UserRole.client) {
            return AppRoutes.home;
          }
          return pendingLink;
        }
        return AppRoutes.home;
      }

      // ── 5. Role guard: worker-only paths ─────────────────────────────────
      // Setup routes (incl. /worker-profile-setup) are exempt: a client may
      // legitimately open worker setup to upgrade to a worker account.
      // Guests are gated like clients — they can view /worker/:id profiles
      // but have no worker account, so jobs/bid routes bounce home.
      if (isLoggedIn && isOnWorkerRoute && !isOnSetup &&
          (cachedRole == UserRole.client || isGuest)) {
        final isWorkerProfilePath = _workerProfilePattern.hasMatch(currentPath);
        if (!isWorkerProfilePath) return AppRoutes.home;
      }

      // ── 6. Normalize /worker-home → /home ────────────────────────────────
      if (isLoggedIn && isOnWorkerHome) return AppRoutes.home;

      return null;
    },

    routes: [
      // ── Splash ─────────────────────────────────────────────────────────
      GoRoute(
        path:        AppRoutes.splash,
        name:        'splash',
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen()),
      ),

      // ── Onboarding ─────────────────────────────────────────────────────
      GoRoute(
        path:        AppRoutes.onboarding,
        name:        'onboarding',
        pageBuilder: (_, s) => _fade(s.pageKey, const OnboardingScreen()),
      ),

      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path:        AppRoutes.phoneAuth,
        name:        'phone-auth',
        pageBuilder: (_, s) => _fade(s.pageKey, const PhoneAuthScreen()),
      ),
      GoRoute(
        path:        AppRoutes.pinVerify,
        name:        'pin-verify',
        pageBuilder: (_, s) => _fade(s.pageKey, const PinVerifyScreen()),
      ),
      GoRoute(
        path:        AppRoutes.pendingApproval,
        name:        'pending-approval',
        pageBuilder: (_, s) => _fade(s.pageKey, const PendingApprovalScreen()),
      ),
      GoRoute(
        path:        AppRoutes.accountPin,
        name:        'account-pin',
        pageBuilder: (_, s) => _fade(s.pageKey, const AccountPinScreen()),
      ),

      // ── Account setup ───────────────────────────────────────────────────
      GoRoute(
        path:        AppRoutes.roleSelection,
        name:        'role-selection',
        pageBuilder: (_, s) => _fade(s.pageKey, const RoleSelectionScreen()),
      ),
      GoRoute(
        path:        AppRoutes.userProfileSetup,
        name:        'user-profile-setup',
        pageBuilder: (_, s) => _fade(s.pageKey, const UserProfileScreen()),
      ),
      GoRoute(
        path:        AppRoutes.workerProfileSetup,
        name:        'worker-profile-setup',
        pageBuilder: (_, s) => _fade(s.pageKey, const WorkerProfileSetupScreen()),
      ),

      // ── Main navigation shell ────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainNavigationScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path:        AppRoutes.home,
              name:        'home',
              pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path:        AppRoutes.workerJobs,
              name:        'worker-jobs',
              pageBuilder: (_, __) => const NoTransitionPage(child: WorkerJobsScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path:        AppRoutes.settings,
              name:        'settings',
              pageBuilder: (_, __) => const NoTransitionPage(child: SettingsScreen()),
            ),
          ]),
        ],
      ),

      // ── Feature routes ──────────────────────────────────────────────────

      GoRoute(
        path:        AppRoutes.subscription,
        name:        'subscription',
        pageBuilder: (_, s) => _fade(s.pageKey, const SubscriptionScreen()),
      ),

      GoRoute(
        path:        AppRoutes.serviceRequest,
        name:        'service-request',
        pageBuilder: (_, s) {
          final extra       = s.extra as Map<String, dynamic>?;
          final isEmergency = extra?['isEmergency'] as bool? ?? false;
          return _fade(s.pageKey, ServiceRequestScreen(isEmergency: isEmergency));
        },
      ),
      GoRoute(
        path:        AppRoutes.workerProfile,
        name:        'worker-profile',
        pageBuilder: (_, s) {
          final workerId = s.pathParameters['id'] ?? '';
          return _fade(s.pageKey, WorkerProfileScreen(workerId: workerId));
        },
      ),
      GoRoute(
        path:        AppRoutes.editProfile,
        name:        'edit-profile',
        pageBuilder: (_, s) => _fade(s.pageKey, const EditProfileScreen()),
      ),
      GoRoute(
        path:        AppRoutes.notifications,
        name:        'notifications',
        pageBuilder: (_, s) => _fade(s.pageKey, const NotificationsScreen()),
      ),
      GoRoute(
        path:        AppRoutes.notificationsInbox,
        name:        'notificationsInbox',
        pageBuilder: (_, s) => _fade(s.pageKey, const NotificationsInboxScreen()),
      ),
      GoRoute(
        path:        AppRoutes.about,
        name:        'about',
        pageBuilder: (_, s) => _fade(s.pageKey, const AboutScreen()),
      ),
      GoRoute(
        path:        AppRoutes.help,
        name:        'help',
        pageBuilder: (_, s) => _fade(s.pageKey, const HelpScreen()),
      ),

      // ── Bid model routes ────────────────────────────────────────────────

      GoRoute(
        path:        '/service-request/:id/bids',
        name:        'bids-list',
        pageBuilder: (_, s) =>
            _fade(s.pageKey, BidsListScreen(requestId: s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path:        '/service-request/:id/tracking',
        name:        'request-tracking',
        pageBuilder: (_, s) =>
            _fade(s.pageKey, RequestTrackingScreen(requestId: s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path:        '/service-request/:id/rating',
        name:        'client-rating',
        pageBuilder: (_, s) =>
            _fade(s.pageKey, RatingScreen(requestId: s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path:        '/worker/jobs/:id',
        name:        'worker-job-detail',
        pageBuilder: (_, s) =>
            _fade(s.pageKey, JobDetailScreen(jobId: s.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path:        '/worker/jobs/:id/bid',
        name:        'submit-bid',
        pageBuilder: (_, s) =>
            _fade(s.pageKey, SubmitBidScreen(requestId: s.pathParameters['id'] ?? '')),
      ),
    ],

    errorBuilder: (context, state) {
      final auth = ref.read(authServiceProvider);
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(context.tr('error.page_not_found'),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(state.uri.toString(),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    context.go(auth.isLoggedIn ? AppRoutes.home : AppRoutes.phoneAuth),
                child: Text(context.tr('error.go_home')),
              ),
            ],
          ),
        ),
      );
    },
  );
});

// ── _UserIdentityListenable ────────────────────────────────────────────────

class _UserIdentityListenable extends ChangeNotifier {
  final AuthService _authService;
  String? _lastUid;

  _UserIdentityListenable(this._authService) {
    _authService.addListener(_onAuthChanged);
    _lastUid = _authService.user?.uid;
  }

  void _onAuthChanged() {
    final newUid = _authService.user?.uid;
    if (newUid != _lastUid) {
      _lastUid = newUid;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
}

// ── Page transition helper ─────────────────────────────────────────────────

CustomTransitionPage<void> _fade(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key:                       key,
    child:                     child,
    transitionDuration:        const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(
        parent:       animation,
        curve:        Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
      child: child,
    ),
  );
}
