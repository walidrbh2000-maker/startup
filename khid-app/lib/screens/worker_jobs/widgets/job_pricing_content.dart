// lib/screens/worker_jobs/widgets/job_pricing_content.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_info_row.dart';

class JobPricingContent extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;

  const JobPricingContent({
    super.key,
    required this.job,
    required this.isDark,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Column(
        children: [
          if (job.estimatedPrice != null)
            JobInfoRow(
              icon:  Icons.attach_money_rounded,
              label: ctx.tr('worker_jobs.estimated_price'),
              value: '${ctx.tr('common.currency')} ${job.estimatedPrice!.toStringAsFixed(0)}',
              isDark: isDark,
            ),
          if (job.finalPrice != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            JobInfoRow(
              icon:      Icons.payments_rounded,
              label:     ctx.tr('worker_jobs.final_price'),
              value:     '${ctx.tr('common.currency')} ${job.finalPrice!.toStringAsFixed(0)}',
              isDark:    isDark,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }
}