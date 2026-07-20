// lib/screens/worker_jobs/widgets/job_completed_badge.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobCompletedBadge extends StatelessWidget {
  final bool isDark;

  const JobCompletedBadge({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.buttonHeightMd,
      decoration: BoxDecoration(
        color:        AppTheme.acceptGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border:       Border.all(color: AppTheme.acceptGreen.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded, color: AppTheme.acceptGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('worker_jobs.job_closed'),
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkSuccess
                    : AppTheme.greenTextLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
