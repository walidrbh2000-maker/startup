// lib/screens/service_request/widgets/bid_card.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/worker_bid_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/app_shimmer.dart';

// ============================================================================
// BID CARD
// Displays a single worker bid: avatar, rating, price, message, CTA.
// Pure presentational — all actions delegated via callbacks.
// ============================================================================

class BidCard extends StatelessWidget {
  final WorkerBidModel bid;
  final bool           isDark;
  final bool           isAccepting;
  final VoidCallback   onAccept;

  const BidCard({
    super.key,
    required this.bid,
    required this.isDark,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final accent     = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final isAccepted = bid.status == BidStatus.accepted;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.7)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isAccepted
              ? AppTheme.acceptGreen.withValues(alpha: 0.4)
              : (isDark
                  ? AppTheme.darkCardBorderOverlay
                  : AppTheme.lightCardBorderOverlay),
          width: isAccepted ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Worker info row ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  width:  44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      bid.workerInitials,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:      accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.workerName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppConstants.spacingXxs),
                      Row(
                        children: [
                          Icon(AppIcons.ratingFilled,
                              size: 12,
                              color: isDark
                                  ? AppTheme.warningAmber
                                  : AppTheme.amberTextLight),
                          const SizedBox(width: AppConstants.spacingXxs),
                          Text(
                            bid.workerAverageRating.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.warningAmber
                                      : AppTheme.amberTextLight,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          Text(
                            '· ${bid.workerJobsCompleted} ${context.tr('bids.missions')}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bid.proposedPrice.toStringAsFixed(0)} ${context.tr('common.currency')}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      bid.estimatedDurationLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Worker message ──────────────────────────────────────────
            if (bid.message != null && bid.message!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSm),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppTheme.darkSurfaceVariant
                          : AppTheme.lightSurfaceVariant)
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  '"${bid.message}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color:
                            isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacingMd),

            // ── Accept / Selected CTA ───────────────────────────────────
            if (!isAccepted)
              Semantics(
                button:  true,
                label:   context.tr('bids.choose_provider'),
                enabled: !isAccepting,
                child: SizedBox(
                  width:  double.infinity,
                  height: AppConstants.buttonHeightSm,
                  child: ElevatedButton(
                    onPressed: isAccepting ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                    ),
                    child: isAccepting
                        ? SizedBox(
                            width:  AppConstants.spinnerSizeLg,
                            height: AppConstants.spinnerSizeLg,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text(
                            context.tr('bids.choose_provider'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                ),
              )
            else
              Container(
                width:  double.infinity,
                height: AppConstants.buttonHeightSm,
                decoration: BoxDecoration(
                  color: AppTheme.acceptGreen.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.check,
                        size: 16,
                        color: isDark
                            ? AppTheme.darkSuccess
                            : AppTheme.greenTextLight),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      context.tr('bids.selected'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isDark
                                ? AppTheme.darkSuccess
                                : AppTheme.greenTextLight,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BID CARD SKELETON
// ============================================================================

class BidCardSkeleton extends StatelessWidget {
  final bool isDark;
  const BidCardSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: isDark
                ? AppTheme.darkCardBorderOverlay
                : AppTheme.lightCardBorderOverlay,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                SkeletonBone(width: 44, height: 44, circle: true),
                SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBone(
                          width: 120, height: 11, radius: AppConstants.radiusXs),
                      SizedBox(height: AppConstants.spacingSm),
                      SkeletonBone(
                          width: 80, height: 9, radius: AppConstants.radiusXs),
                    ],
                  ),
                ),
                SkeletonBone(
                    width: 56, height: 16, radius: AppConstants.radiusXs),
              ],
            ),
            SizedBox(height: AppConstants.spacingMd),
            // skeleton matches fixed buttonHeightSm
            SkeletonBone(
              width:  double.infinity,
              height: AppConstants.buttonHeightSm,
              radius: AppConstants.radiusMd,
            ),
          ],
        ),
      ),
    );
  }
}
