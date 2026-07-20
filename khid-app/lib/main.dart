// lib/main.dart
//
// STEP 6 MIGRATION:
//   • Removed: import 'package:cloud_firestore/cloud_firestore.dart'
//   • Removed: FirebaseFirestore.instance.settings (persistenceEnabled: true)
//              — offline persistence was Firestore-specific; MongoDB handles
//                durability server-side.
//   • Everything else unchanged.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/core_providers.dart';
import 'providers/auth_providers.dart';
import 'providers/app_lifecycle_provider.dart';
import 'providers/notification_navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'services/device_id_service.dart';
import 'services/language_service.dart';
import 'router/app_router.dart';
import 'utils/app_config.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'utils/localization.dart';
import 'utils/logger.dart';
import 'widgets/biometric_gate.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    AppLogger.info('Initializing Firebase...');
    await Firebase.initializeApp();
    AppLogger.success('Firebase initialized');

    await AppConfig.initialize();
    AppLogger.success('Remote Config initialized');

    // One-time migration: remove deprecated PrefKeys.viewMode key.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('viewMode');

    // Device id must exist before the first API call (X-Device-Id header).
    await DeviceIdService.init();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor:            Colors.transparent,
        systemNavigationBarDividerColor:     Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        statusBarColor:                      Colors.transparent,
      ),
    );

    runApp(const ProviderScope(child: KhidmetiApp()));
  } catch (e, stackTrace) {
    AppLogger.error('Critical initialization error', e, stackTrace);
    FlutterNativeSplash.remove();
    runApp(_buildErrorApp(e));
  }
}

Widget _buildErrorApp(dynamic error) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Initialization Error',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text('$error', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class KhidmetiApp extends ConsumerStatefulWidget {
  const KhidmetiApp({super.key});

  @override
  ConsumerState<KhidmetiApp> createState() => _KhidmetiAppState();
}

class _KhidmetiAppState extends ConsumerState<KhidmetiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final languageService = ref.read(languageServiceProvider);
      await languageService.initialize();
      AppLogger.success('Language service initialized');
    } catch (e) {
      AppLogger.error('Service initialization error', e);
    }

    // Cold start: if a session already exists, bring the push stack online now.
    // The build() listener below handles the fresh-login and sign-out cases.
    if (ref.read(currentUserIdProvider) != null) {
      ref.read(pushNotificationCoordinatorProvider).start().ignore();
    }
  }

  void _onAuthChanged(String? previous, String? next) {
    final coordinator = ref.read(pushNotificationCoordinatorProvider);
    if (next != null && previous == null) {
      coordinator.start().ignore();
    } else if (next == null && previous != null) {
      coordinator.stop().ignore();
    }
  }

  void _handleNotificationNavigation(NotificationNavigationState nav) {
    if (!nav.hasNavigation || nav.isExpired) return;
    final route = _routeForNotification(nav.type, nav.data ?? const {});
    // Cold start: an immediate navigation would be swallowed by the splash
    // gate (redirect pins to /splash until initialized). Park the destination
    // as a pending deep link instead — the splash redirect restores it.
    if (!ref.read(appInitializedProvider)) {
      ref.read(pendingDeepLinkProvider.notifier).state = route;
    } else {
      // push, not go: keep the current screen on the stack so both the
      // in-app back button and the system back gesture return to it.
      ref.read(goRouterProvider).push(route).ignore();
    }
    ref.read(notificationNavigationProvider.notifier).clearNavigation();
  }

  /// Maps a notification's `type` + `data` to a destination route.
  /// Unknown types fall back to the notifications inbox — never a dead end.
  static String _routeForNotification(String? type, Map<String, dynamic> data) {
    final requestId = data['requestId'] as String?;
    switch (type) {
      // Sent to the CLIENT (request owner) → client-facing screens.
      case 'bid_received':
      // Worker declined the job — request reopened, back to reviewing bids.
      case 'job_declined':
        return requestId != null
            ? '/service-request/$requestId/bids'
            : AppRoutes.notificationsInbox;
      case 'job_started':
      case 'job_completed':
      case 'request_updated':
        return requestId != null
            ? '/service-request/$requestId/tracking'
            : AppRoutes.notificationsInbox;
      // Sent to the WORKER → worker-facing job screen.
      case 'bid_accepted':
        return requestId != null
            ? '/worker/jobs/$requestId'
            : AppRoutes.notificationsInbox;
      // Documents approved — the account is unblocked; go through splash so
      // role resolution + the gate drop happen in the normal path. (While
      // parked, the pending screen's own poll usually wins first.)
      case 'verification_approved':
        return AppRoutes.splash;
      default:
        return AppRoutes.notificationsInbox;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    ref.read(appLifecycleProvider.notifier).updateState(state);
  }

  @override
  Widget build(BuildContext context) {
    // Bring the push stack up on fresh login / tear it down on sign-out.
    ref.listen<String?>(currentUserIdProvider, _onAuthChanged);

    // React to a tapped notification by routing to the relevant screen.
    ref.listen<NotificationNavigationState>(
      notificationNavigationProvider,
      (_, next) => _handleNotificationNavigation(next),
    );

    final router        = ref.watch(goRouterProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final themeMode     = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title:         'Khidmeti',
      routerConfig:  router,
      builder: (context, child) =>
          BiometricGate(child: child ?? const SizedBox.shrink()),
      theme:         AppTheme.lightTheme,
      darkTheme:     AppTheme.darkTheme,
      themeMode:     themeMode,
      locale:        currentLocale,
      supportedLocales: LanguageService.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
