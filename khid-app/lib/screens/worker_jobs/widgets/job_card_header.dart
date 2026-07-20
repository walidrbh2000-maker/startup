// lib/screens/worker_jobs/widgets/job_card_header.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import 'job_status_badge.dart';

class JobCardHeader extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final Color serviceColor;
  final Color statusColor;
  final Color accentColor;
  final bool  isDark;

  const JobCardHeader({
    super.key,
    required this.job,
    required this.serviceColor,
    required this.statusColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service icon
        Container(
          width:  46,
          height: 46,
          decoration: BoxDecoration(
            color:  serviceColor.withValues(alpha: 0.15),
            shape:  BoxShape.circle,
            border: Border.all(color: serviceColor.withValues(alpha: 0.25)),
          ),
          child: Icon(
            AppTheme.getProfessionIcon(job.serviceType),
            color: serviceColor,
            size:  22,
          ),
        ),

        const SizedBox(width: AppConstants.spacingMd),

        // Title + client
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight:    FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size:  AppConstants.iconSizeXs,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(width: AppConstants.spacingXs),
                  Expanded(
                    child: Text(
                      job.userName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:      isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                            fontWeight: FontWeight.w400,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Status badge
        JobStatusBadge(
          status: job.status,
          color:  statusColor,
          isDark: isDark,
        ),
      ],
    );
  }
}
