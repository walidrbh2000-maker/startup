// lib/screens/service_request/widgets/worker_card.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// WORKER CARD
// Shows the assigned worker's name and agreed price on the tracking screen.
// ============================================================================

class WorkerCard extends StatelessWidget {
  final ServiceRequestEnhancedModel request;
  final bool                        isDark;

  const WorkerCard({
    super.key,
    required this.request,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
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
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                request.workerName!.isNotEmpty
                    ? request.workerName![0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  request.workerName!,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (request.agreedPrice != null)
                  Text(
                    '${context.tr('tracking.agreed_price')}: '
                    '${request.agreedPrice!.toStringAsFixed(0)} '
                    '${context.tr('common.currency')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
