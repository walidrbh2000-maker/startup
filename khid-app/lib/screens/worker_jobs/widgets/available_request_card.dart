// lib/screens/worker_jobs/widgets/available_request_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../models/message_enums.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'browse_card_icon_button.dart';
import 'countdown_text.dart';
import 'job_location_map_sheet.dart';

class AvailableRequestCard extends StatelessWidget {
  final ServiceRequestEnhancedModel request;
  final bool isDark;
  final Color accent;

  /// True when the current worker already has a pending bid on this request.
  final bool hasMyBid;

  const AvailableRequestCard({
    super.key,
    required this.request,
    required this.isDark,
    required this.accent,
    required this.hasMyBid,
  });

  @override
  Widget build(BuildContext context) {
    final serviceColor =
        isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final serviceIcon  = AppTheme.getProfessionIcon(request.serviceType);
    final isUrgent     = request.priority == ServicePriority.urgent;

    return Semantics(
      button: true,
      label: context.tr('services.${request.serviceType}'),
      child: GestureDetector(
        onTap: () => context.push(
          AppRoutes.workerJobDetail.replaceAll(':id', request.id),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSurface.withValues(alpha: 0.6)
                : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              // Urgent cards get the theme-correct error tint.
              color: isUrgent
                  ? (isDark ? AppTheme.darkError : AppTheme.lightError)
                      .withValues(alpha: 0.3)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: icon / title / bid badge ──────────────────
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: serviceColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                      child: Icon(serviceIcon, size: 20, color: serviceColor),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('services.${request.serviceType}'),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            request.userAddress.isNotEmpty
                                ? request.userAddress
                                : context.tr('common.not_specified'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Bid count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: request.bidCount == 0
                            ? AppTheme.acceptGreen.withValues(alpha: 0.12)
                            : (isDark
                                    ? AppTheme.darkSurfaceVariant
                                    : AppTheme.lightSurfaceVariant)
                                .withValues(alpha: 0.7),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Text(
                        request.bidCount == 0
                            ? context.tr('worker_browse.be_first')
                            : '${request.bidCount} ${context.tr('bids.offers')}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: request.bidCount == 0
                                  ? (isDark
                                      ? AppTheme.darkSuccess
                                      : AppTheme.greenTextLight)
                                  : (isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),

                // ── Budget range ──────────────────────────────────────
                if (request.budgetMin != null || request.budgetMax != null) ...[
                  const SizedBox(height: AppConstants.spacingXs),
                  Row(
                    children: [
                      Icon(
                        AppIcons.wallet,
                        size: AppConstants.iconSizeXs,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        request.displayAmount != null
                            ? '${request.displayAmount} ${context.tr('common.currency')}'
                            : '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText,
                            ),
                      ),
                    ],
                  ),
                ],

                // ── Countdown ─────────────────────────────────────────
                if (request.biddingDeadlineAt != null)
                  CountdownText(deadline: request.biddingDeadlineAt!),

                const SizedBox(height: AppConstants.spacingMd),

                // ── Action row ────────────────────────────────────────
                Row(
                  children: [
                    BrowseCardIconButton(
                      icon: AppIcons.location,
                      color: accent,
                      semanticsLabel: context.tr('worker_jobs.view_location'),
                      onTap: () => JobLocationMapSheet.show(
                        context,
                        latitude: request.userLatitude,
                        longitude: request.userLongitude,
                        address: request.userAddress,
                        clientName: request.userName,
                      ),
                    ),
                    if (request.userPhone.isNotEmpty) ...[
                      const SizedBox(width: AppConstants.spacingXs),
                      BrowseCardIconButton(
                        icon: AppIcons.phone,
                        color: accent,
                        semanticsLabel:
                            context.tr('worker_jobs.client_phone'),
                        onTap: () =>
                            launchUrl(Uri.parse('tel:${request.userPhone}')),
                      ),
                    ],
                    const SizedBox(width: AppConstants.spacingSm),
                    if (hasMyBid)
                      Expanded(
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusMd),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            context.tr('worker_browse.bid_sent'),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkAccentText
                                      : accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.submitBid
                                .replaceAll(':id', request.id),
                          ),
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMd),
                            ),
                            child: Text(
                              context.tr('worker_browse.make_offer'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
