// lib/screens/notifications/notifications_screen.dart
//
// Notification preference toggles (opened from Settings). The received
// inbox lives in notifications_inbox_screen.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/app_sliver_header.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/app_section_header.dart';
import '../../providers/core_providers.dart';
import '../../providers/notifications_prefs_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(notificationPrefsProvider);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            // ── Scrolling app bar ────────────────────────────────────────────
            AppSliverHeader(
              title: context.tr('notifications.title'),
            ),

            // ── Loading — AppBar stays visible while spinner shows in body ───
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )

            // ── Content ──────────────────────────────────────────────────────
            else
              SliverPadding(
                padding: EdgeInsetsDirectional.only(
                  top:    AppConstants.spacingMd,
                  bottom: MediaQuery.paddingOf(context).bottom +
                      AppConstants.spacingLg,
                  start:  AppConstants.paddingMd,
                  end:    AppConstants.paddingMd,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    if (state.systemPermissionDenied) ...[
                      const _PermissionWarningBanner(),
                      const SizedBox(height: AppConstants.spacingMd),
                    ],

                    AppSectionHeader(label: context.tr('notifications.activity')),
                    const SizedBox(height: AppConstants.spacingSm),

                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.requests,
                      title:     context.tr('notifications.new_requests'),
                      subtitle:  context.tr('notifications.new_requests_sub'),
                      value:     state.newRequests,
                      onChanged: (v) => ref
                          .read(notificationPrefsProvider.notifier)
                          .setNewRequests(v),
                    ),
                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.jobs,
                      title:     context.tr('notifications.bid_received'),
                      subtitle:  context.tr('notifications.bid_received_sub'),
                      value:     state.bidReceived,
                      onChanged: (v) => ref
                          .read(notificationPrefsProvider.notifier)
                          .setBidReceived(v),
                    ),
                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.messages,
                      title:     context.tr('notifications.chat_messages'),
                      subtitle:  context.tr('notifications.chat_messages_sub'),
                      value:     state.chatMessages,
                      onChanged: (v) => ref
                          .read(notificationPrefsProvider.notifier)
                          .setChatMessages(v),
                    ),

                    const SizedBox(height: AppConstants.spacingMdLg),
                    AppSectionHeader(label: context.tr('notifications.marketing')),
                    const SizedBox(height: AppConstants.spacingSm),

                    _NotifToggleTile(
                      isDark:    isDark,
                      icon:      AppIcons.notifications,
                      title:     context.tr('notifications.promotions'),
                      subtitle:  context.tr('notifications.promotions_sub'),
                      value:     state.promotions,
                      onChanged: (v) => ref
                          .read(notificationPrefsProvider.notifier)
                          .setPromotions(v),
                    ),

                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE — PERMISSION WARNING BANNER
// ============================================================================

class _PermissionWarningBanner extends ConsumerWidget {
  // banner subtree is canonicalised and skipped during parent rebuilds.
  const _PermissionWarningBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color:        theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(AppIcons.notificationsOff,
              color: theme.colorScheme.onErrorContainer,
              size: AppConstants.iconSizeSm),
          const SizedBox(width: AppConstants.spacingSmMd),
          Expanded(
            child: Text(
              context.tr('notifications.system_disabled'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            // Button says "Settings" — take the user there, don't hint at it.
            onPressed: () =>
                ref.read(permissionServiceProvider).openSettings(),
            child: Text(
              context.tr('common.settings'),
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PRIVATE — NOTIFICATION TOGGLE TILE
// ============================================================================

class _NotifToggleTile extends StatelessWidget {
  final bool               isDark;
  final IconData           icon;
  final String             title;
  final String             subtitle;
  final bool               value;
  final ValueChanged<bool> onChanged;

  const _NotifToggleTile({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One restrained icon colour for every row — no rainbow chips (same rule
    // as settings/about). Accent stays reserved for the Switch + header mark.
    final mutedIcon =
        isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    return Semantics(
      label:   title,
      toggled: value,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spacingXxs),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: InkWell(
            onTap:        () => onChanged(!value),
            borderRadius: BorderRadius.circular(AppConstants.radiusTile),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
                vertical:   AppConstants.spacingTileInner,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusTile),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: AppConstants.cardBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:  AppConstants.iconContainerXl,
                    height: AppConstants.iconContainerXl,
                    decoration: BoxDecoration(
                      color: mutedIcon.withValues(
                          alpha: AppConstants.opacityIconBgAlt),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(icon, color: mutedIcon,
                        size: AppConstants.iconSizeSm),
                  ),
                  const SizedBox(width: AppConstants.spacingTileInner),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize:   AppConstants.fontSizeTileLg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXxs),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Switch(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
