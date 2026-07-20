// lib/screens/service_request/widgets/rating_nudge.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// RATING NUDGE
// CTA banner shown when job is completed but not yet rated.
// ============================================================================

class RatingNudge extends StatelessWidget {
  final String requestId;
  final bool   isDark;

  const RatingNudge({
    super.key,
    required this.requestId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color:        AppTheme.warningAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border:       Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.ratingFilled, size: 20, color: AppTheme.warningAmber),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              context.tr('tracking.rate_prompt'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Semantics(
            button: true,
            label:  context.tr('rating.rate_now'),
            child: GestureDetector(
              onTap: () => context.push(
                AppRoutes.clientRating.replaceAll(':id', requestId),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingChipGap,
                  vertical:   AppConstants.spacingXs,
                ),
                decoration: BoxDecoration(
                  color:        AppTheme.warningAmber,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  context.tr('rating.rate_now'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:      Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
