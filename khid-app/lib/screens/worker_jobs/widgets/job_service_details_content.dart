// lib/screens/worker_jobs/widgets/job_service_details_content.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_info_row.dart';

class JobServiceDetailsContent extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;

  const JobServiceDetailsContent({
    super.key,
    required this.job,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Column(
        children: [
          JobInfoRow(
            icon:   AppTheme.getProfessionIcon(job.serviceType),
            label:  context.tr('worker_jobs.service_type'),
            value:  context.tr('services.${job.serviceType}'),
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          JobInfoRow(
            icon:   Icons.tag_rounded,
            label:  context.tr('worker_jobs.request_id'),
            // .clamp(0, 8) — safe for any id length.
            value:  '#${job.id.substring(0, job.id.length.clamp(0, 8)).toUpperCase()}',
            isDark: isDark,
            mono:   true,
          ),
        ],
      ),
    );
  }
}
