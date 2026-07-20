// lib/screens/worker_jobs/widgets/job_loading_btn.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class JobLoadingBtn extends StatelessWidget {
  final Color accentColor;

  const JobLoadingBtn({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.buttonHeightMd,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: accentColor,
          ),
        ),
      ),
    );
  }
}
