// lib/screens/worker_jobs/widgets/job_schedule_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_info_row.dart';

class JobScheduleContent extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;

  const JobScheduleContent({
    super.key,
    required this.job,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMMM d, yyyy').format(job.scheduledDate);
    final time =
        '${job.scheduledTime.hour.toString().padLeft(2, '0')}:${job.scheduledTime.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Column(
        children: [
          JobInfoRow(
            icon:   Icons.calendar_today_rounded,
            label:  context.tr('requests.scheduled_date'),
            value:  date,
            isDark: isDark,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          JobInfoRow(
            icon:   Icons.access_time_rounded,
            label:  context.tr('requests.scheduled_time'),
            value:  time,
            isDark: isDark,
          ),
          if (job.estimatedDuration != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            JobInfoRow(
              icon:   Icons.timer_rounded,
              label:  context.tr('worker_jobs.estimated_duration'),
              value:  '${job.estimatedDuration} min',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}
