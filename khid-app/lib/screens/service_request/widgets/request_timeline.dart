// lib/screens/service_request/widgets/request_timeline.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// REQUEST TIMELINE
// 4-step progress indicator: Posted → Selected → Started → Done.
// ============================================================================

class RequestTimeline extends StatelessWidget {
  final ServiceRequestEnhancedModel request;
  final bool                        isDark;

  const RequestTimeline({
    super.key,
    required this.request,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: context.tr('tracking.step_posted'), done: true),
      (
        label: context.tr('tracking.step_selected'),
        done:  request.status != ServiceStatus.open &&
               request.status != ServiceStatus.awaitingSelection,
      ),
      (
        label: context.tr('tracking.step_started'),
        done:  request.status == ServiceStatus.inProgress ||
               request.status == ServiceStatus.completed,
      ),
      (
        label: context.tr('tracking.step_done'),
        done:  request.status == ServiceStatus.completed,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.5)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark
              ? AppTheme.darkCardBorderOverlay
              : AppTheme.lightCardBorderOverlay,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('tracking.timeline').toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                  letterSpacing: 0.7,
                  fontWeight:    FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          ...steps.asMap().entries.map((entry) {
            final i      = entry.key;
            final step   = entry.value;
            final isLast = i == steps.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width:  12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.done
                            ? AppTheme.acceptGreen
                            : (isDark
                                ? AppTheme.darkSurfaceVariant
                                : AppTheme.lightSurfaceVariant),
                        border: Border.all(
                          color: step.done
                              ? AppTheme.acceptGreen
                              : (isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder),
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Text(
                      step.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: step.done
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: step.done
                                ? (isDark
                                    ? AppTheme.darkText
                                    : AppTheme.lightText)
                                : (isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText),
                          ),
                    ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: AppConstants.spacingXs, top: 2, bottom: 2),
                    child: Container(
                      width:  1.5,
                      height: 18,
                      color: isDark
                          ? AppTheme.darkBorder.withValues(alpha: 0.5)
                          : AppTheme.lightBorder,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
