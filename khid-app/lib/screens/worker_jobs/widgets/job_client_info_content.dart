// lib/screens/worker_jobs/widgets/job_client_info_content.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_info_row.dart';

class JobClientInfoContent extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;

  const JobClientInfoContent({
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
            icon: Icons.person_rounded,
            label: context.tr('worker_jobs.client_name'),
            value: job.userName,
            isDark: isDark,
          ),
          if (job.userPhone.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingSm),
            JobInfoRow(
              icon: Icons.phone_rounded,
              label: context.tr('worker_jobs.client_phone'),
              value: job.userPhone,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

