// lib/screens/service_request/widgets/tracking_body.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/back_button.dart';
import 'rating_nudge.dart';
import 'rating_summary.dart';
import 'request_timeline.dart';
import 'whatsapp_contact_button.dart';
import 'worker_card.dart';

// ============================================================================
// TRACKING BODY
// Main scrollable content of RequestTrackingScreen.
// Pure presentational — receives resolved ServiceRequestEnhancedModel.
// ============================================================================

class TrackingBody extends StatelessWidget {
  final ServiceRequestEnhancedModel request;
  final bool                        isDark;

  const TrackingBody({
    super.key,
    required this.request,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor  = AppTheme.getStatusColor(request.status, isDark);
    final serviceColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final serviceIcon  = AppTheme.getProfessionIcon(request.serviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── App bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMd,
              AppConstants.paddingMd,
              AppConstants.paddingMd,
              0),
          child: Row(
            children: [
              AppBackButton(isDark: isDark),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Text(
                  context.tr('tracking.title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  request.status.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:      statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),

        // ── Scrollable content ───────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppConstants.paddingMd,
              AppConstants.spacingMd,
              AppConstants.paddingMd,
              AppConstants.spacingXl + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service summary
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface.withValues(alpha: 0.6)
                        : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkCardBorderOverlay
                          : AppTheme.lightCardBorderOverlay,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width:  AppConstants.serviceIconContainerSize,
                        height: AppConstants.serviceIconContainerSize,
                        decoration: BoxDecoration(
                          color: serviceColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                        ),
                        child:
                            Icon(serviceIcon, size: 20, color: serviceColor),
                      ),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context
                                  .tr('services.${request.serviceType}'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (request.userAddress.isNotEmpty)
                              Text(
                                request.userAddress,
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
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.spacingMd),

                if (request.workerName != null)
                  WorkerCard(request: request, isDark: isDark),

                const SizedBox(height: AppConstants.spacingMd),

                if (request.workerId != null &&
                    (request.status == ServiceStatus.bidSelected ||
                        request.status == ServiceStatus.inProgress ||
                        request.status == ServiceStatus.completed))
                  WhatsAppContactButton(request: request, isDark: isDark),

                const SizedBox(height: AppConstants.spacingMd),

                RequestTimeline(request: request, isDark: isDark),

                const SizedBox(height: AppConstants.spacingMd),

                if (request.status == ServiceStatus.completed &&
                    !request.isRatedByClient)
                  RatingNudge(requestId: request.id, isDark: isDark),

                if (request.isRatedByClient)
                  RatingSummary(
                      rating: request.clientRating!, isDark: isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
