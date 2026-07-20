// lib/providers/notifications_inbox_provider.dart
//
// The received-notifications inbox (home bell). Backend already exposes
// GET /notifications + PATCH read / read-all — this just fetches and lets the
// screen mark items read. Distinct from notifications_prefs_provider, which
// owns the per-type toggle settings shown from the Settings screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'core_providers.dart';

/// The user's notifications, newest first. autoDispose so it refetches each time
/// the inbox is opened; invalidate it after marking read to refresh the list.
final notificationsInboxProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.read(apiServiceProvider).fetchNotifications();
});
