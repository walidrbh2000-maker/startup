// lib/screens/service_request/widgets/request_summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/message_enums.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// REQUEST SUMMARY CARD
// Read-only key-value table shown on step 3 (Confirm).
// ============================================================================

class RequestSummaryCard extends StatelessWidget {
  final String? serviceType;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final int mediaCount;
  final ServicePriority priority;
  final bool isDark;

  const RequestSummaryCard({
    super.key,
    required this.serviceType,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.mediaCount,
    required this.priority,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE d MMM', Localizations.localeOf(context).languageCode)
        .format(scheduledDate);
    final timeStr =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    final rows = <(String, String, Color?)>[
      (
        context.tr('request_form.section_service'),
        serviceType != null
            ? context.tr('services.$serviceType')
            : '–',
        null,
      ),
      (
        context.tr('request_form.section_when'),
        '$dateStr · $timeStr',
        null,
      ),
      (
        context.tr('request_form.section_media'),
        mediaCount > 0
            ? '$mediaCount'
            : context.tr('request_form.optional_tag'),
        null,
      ),
      (
        context.tr('request_form.section_priority'),
        context.tr(
          priority == ServicePriority.urgent
              ? 'request_form.priority_urgent'
              : 'request_form.priority_normal',
        ),
        priority == ServicePriority.urgent
            ? (isDark ? AppTheme.warningAmber : AppTheme.amberTextLight)
            : (isDark ? AppTheme.priorityNormalDark : AppTheme.greenTextLight),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.45)
            : AppTheme.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final (label, value, valueColor) = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMd,
                  vertical: AppConstants.spacingMd,
                ),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: valueColor,
                          ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                  indent: AppConstants.paddingMd,
                  endIndent: AppConstants.paddingMd,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
