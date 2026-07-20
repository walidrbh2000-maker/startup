// lib/services/push_notification_coordinator.dart
//
// Wires the previously-dormant push stack together:
//
//   FirebaseMessaging (FCM)  ─┬─ onMessage          → show a local notification
//                             ├─ onMessageOpenedApp → feed navigation
//                             └─ getInitialMessage  → feed navigation (cold start)
//
//   NotificationPushService  → permission + token registration with the backend
//   NotificationService      → local (foreground) notification display + tap
//
// Lifecycle: start() is called once the user is authenticated; stop() on sign-out.
// Every external call is wrapped so a notification failure NEVER breaks the app —
// the in-app realtime layer (WebSocket) is unaffected either way.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../utils/logger.dart';
import 'notification_push_service.dart';
import 'notification_service.dart';

typedef NotificationNavigate = void Function(Map<String, dynamic> data);

class PushNotificationCoordinator {
  final NotificationPushService _pushService;
  final NotificationService     _localService;

  /// Called when the user taps a notification. Receives the FCM data payload.
  final NotificationNavigate _onNavigate;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  bool _started = false;

  PushNotificationCoordinator({
    required NotificationPushService pushService,
    required NotificationService     localService,
    required NotificationNavigate    onNavigate,
  })  : _pushService  = pushService,
        _localService = localService,
        _onNavigate   = onNavigate;

  bool get isStarted => _started;

  /// Idempotent — safe to call multiple times (e.g. from both the startup
  /// already-logged-in path and the fresh-login listener).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    AppLogger.info('PushNotificationCoordinator: starting');

    // 1) Local display channel + tap handler (foreground notifications + taps).
    try {
      await _localService.initialize(onSelectNotification: _onLocalTap);
    } catch (e) {
      AppLogger.error('PushCoordinator: local notification init failed', e);
    }

    // 2) FCM permission + token registration (non-fatal on failure).
    try {
      await _pushService.initialize();
    } catch (e) {
      AppLogger.error('PushCoordinator: push service init failed', e);
    }

    // 3) FCM runtime handlers.
    try {
      _onMessageSub = FirebaseMessaging.onMessage.listen(
        _onForegroundMessage,
        onError: (Object e) => AppLogger.error('PushCoordinator: onMessage', e),
      );
      _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => _handleOpened(m, source: 'background-tap'),
        onError: (Object e) => AppLogger.error('PushCoordinator: onOpened', e),
      );

      // Cold start from a killed state via a notification tap.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleOpened(initial, source: 'cold-start');
      }
    } catch (e) {
      AppLogger.error('PushCoordinator: handler registration failed', e);
    }

    AppLogger.success('PushNotificationCoordinator: started');
  }

  /// Tears down handlers on sign-out. Keeps the process clean for the next user.
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    _onMessageSub = null;
    _onOpenedSub  = null;
    AppLogger.info('PushNotificationCoordinator: stopped');
  }

  // ── FCM → local display (foreground) ───────────────────────────────────────

  /// Maps a push `type` to its Settings toggle. Unknown types are always
  /// shown — a new backend event must never be silently droppable.
  static String? _prefKeyForType(String? type) {
    switch (type) {
      case 'request_created':
      case 'new_request':
        return PrefKeys.notifNewRequests;
      case 'bid_received':
        return PrefKeys.notifBidReceived;
      case 'chat_message':
        return PrefKeys.notifChatMessages;
      case 'admin_broadcast':
      case 'promotion':
        return PrefKeys.notifPromotions;
      default:
        return null;
    }
  }

  Future<bool> _isTypeEnabled(String? type) async {
    final key = _prefKeyForType(type);
    if (key == null) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Same defaults as NotificationPrefsState: promotions opt-in, rest on.
      return prefs.getBool(key) ?? (key != PrefKeys.notifPromotions);
    } catch (_) {
      return true; // never drop a notification over a prefs read failure
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Settings → Notifications toggles gate the foreground display.
    if (!await _isTypeEnabled(message.data['type'] as String?)) {
      AppLogger.info('PushCoordinator: "${message.data['type']}" muted by prefs');
      return;
    }

    // Android does NOT auto-display notification messages while in foreground,
    // so we render them ourselves. Data-only messages are shown too when they
    // carry a title/body.
    final title = message.notification?.title ??
        (message.data['title'] as String?) ?? '';
    final body = message.notification?.body ??
        (message.data['body'] as String?) ?? '';

    if (title.trim().isEmpty && body.trim().isEmpty) {
      // Pure silent data message — nothing to display; realtime layer handles it.
      return;
    }

    // NotificationService rejects empty title/body and caps title at 100 / body
    // at 500 chars. Guarantee valid, bounded content so nothing is dropped.
    final safeTitle = _clamp(title.trim().isEmpty ? 'Khidmeti' : title, 100);
    final safeBody  = _clamp(body.trim().isEmpty ? safeTitle : body, 500);

    try {
      await _localService.showNotification(
        id:       _notificationId(message),
        title:    safeTitle,
        body:     safeBody,
        payload:  jsonEncode(message.data),
        priority: NotificationPriority.high,
      );
    } catch (e) {
      AppLogger.error('PushCoordinator: showNotification failed', e);
    }
  }

  // ── Taps → navigation ──────────────────────────────────────────────────────

  void _handleOpened(RemoteMessage message, {required String source}) {
    AppLogger.info('PushCoordinator: notification opened ($source)');
    _safeNavigate(_stringKeyedMap(message.data));
  }

  void _onLocalTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _safeNavigate(decoded.map((k, v) => MapEntry(k.toString(), v)));
      }
    } catch (e) {
      AppLogger.error('PushCoordinator: payload decode failed', e);
    }
  }

  void _safeNavigate(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    try {
      _onNavigate(data);
    } catch (e) {
      AppLogger.error('PushCoordinator: navigate failed', e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _stringKeyedMap(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k.toString(), v));

  String _clamp(String s, int max) => s.length <= max ? s : s.substring(0, max);

  /// A stable, 32-bit-safe notification id (flutter_local_notifications requires
  /// id ≤ 2^31-1). Derived from the FCM messageId when present.
  int _notificationId(RemoteMessage message) {
    final seed = message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}';
    return seed.hashCode & 0x7fffffff;
  }
}
