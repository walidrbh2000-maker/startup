// lib/screens/notifications/notifications_inbox_screen.dart
//
// The received-notifications inbox opened from the home bell. Lists what the
// backend push pipeline recorded (GET /notifications); tapping marks an item
// read. Notification *settings* live in a separate screen (from Settings).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/notification_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/notifications_inbox_provider.dart';
import '../../providers/notification_navigation_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/logger.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/app_sliver_header.dart';
import '../../widgets/back_button.dart';
import '../../widgets/feature_error_state.dart';
import '../../widgets/wordmark.dart';

class NotificationsInboxScreen extends ConsumerWidget {
  const NotificationsInboxScreen({super.key});

  /// Cases mirror the backend push types (push-sender.service.ts):
  /// bid_received, bid_accepted, job_started, job_completed, admin_broadcast.
  IconData _iconFor(String type) {
    switch (type) {
      case 'bid_received':
        return Icons.local_offer_outlined;
      case 'bid_accepted':
        return Icons.check_circle_outline;
      case 'job_started':
        return Icons.play_circle_outline;
      case 'job_completed':
        return Icons.task_alt_rounded;
      case 'job_declined':
        return Icons.person_off_outlined;
      case 'admin_broadcast':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _onTap(WidgetRef ref, NotificationModel n) async {
    if (!n.isRead) {
      // Best-effort: a failed PATCH (offline) must not block the deep-link.
      try {
        await ref.read(apiServiceProvider).markNotificationRead(n.id);
        ref.invalidate(notificationsInboxProvider);
      } catch (e) {
        AppLogger.warning('markNotificationRead failed: $e');
      }
    }
    // Best-effort deep-link, same channel the push-tap path uses.
    ref.read(notificationNavigationProvider.notifier)
        .handleNotificationTap({'type': n.type, ...n.data});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final async = ref.watch(notificationsInboxProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // Reached with go() from notification taps (empty stack) — the guard
      // sends system-back home instead of exiting the app.
      child: AppBackGuard(
        child: Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            slivers: [
              AppSliverHeader(
                title: context.tr('notifications.title'),
              ),
              ...async.when<List<Widget>>(
                loading: () => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (_, __) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: FeatureErrorState(
                      isDark:     isDark,
                      errorTitle: context.tr('errors.generic'),
                      onRetry:    () => ref.invalidate(notificationsInboxProvider),
                      retryLabel: context.tr('common.retry'),
                      icon:       Icons.notifications_off_outlined,
                    ),
                  ),
                ],
                data: (items) {
                  if (items.isEmpty) {
                    return [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyInbox(
                          text:   context.tr('notifications.empty'),
                          isDark: isDark,
                        ),
                      ),
                    ];
                  }
                  final hasUnread = items.any((n) => !n.isRead);
                  return [
                    if (hasUnread)
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: AppConstants.paddingMd,
                              top: AppConstants.spacingSm,
                            ),
                            child: TextButton.icon(
                              onPressed: () async {
                                await ref.read(apiServiceProvider).markAllNotificationsRead();
                                ref.invalidate(notificationsInboxProvider);
                              },
                              icon:  const Icon(Icons.done_all, size: 18),
                              label: Text(context.tr('notifications.mark_all_read')),
                            ),
                          ),
                        ),
                      ),
                    SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) => _NotificationTile(
                        n:      items[i],
                        icon:   _iconFor(items[i].type),
                        isDark: isDark,
                        onTap:  () => _onTap(ref, items[i]),
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel n;
  final IconData          icon;
  final bool              isDark;
  final VoidCallback      onTap;

  const _NotificationTile({
    required this.n,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final unread = !n.isRead;

    final locale = Localizations.localeOf(context).languageCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Point Final accent edge rule — marks an unread item without a
              // full-bleed tint wash.
              Container(
                width: 3,
                color: unread ? accent : Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMd,
                    vertical:   AppConstants.spacingSmMd,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width:  AppConstants.iconContainerXl,
                        height: AppConstants.iconContainerXl,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.15),
                        ),
                        child: Icon(icon,
                            size: AppConstants.iconSizeSm, color: accent),
                      ),
                      const SizedBox(width: AppConstants.spacingSmMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            if (n.body.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacingXxs),
                              Text(
                                n.body,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppConstants.spacingXs),
                            Text(
                              DateFormat('MMM d, HH:mm', locale)
                                  .format(n.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsetsDirectional.only(
                              start: AppConstants.spacingSm,
                              top:   AppConstants.spacingXs),
                          width:  AppConstants.statusDotSize,
                          height: AppConstants.statusDotSize,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: accent),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  final String text;
  final bool   isDark;
  const _EmptyInbox({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: AppConstants.iconSizeLg2, color: muted.withValues(alpha: 0.4)),
          const SizedBox(height: AppConstants.spacingLg),
          // Accent hairline — the Point Final rule motif.
          const AccentRule(),
          const SizedBox(height: AppConstants.spacingMd),
          Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
