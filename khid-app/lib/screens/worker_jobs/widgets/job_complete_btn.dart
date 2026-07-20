// lib/screens/worker_jobs/widgets/job_complete_btn.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobCompleteBtn extends StatelessWidget {
  final Color        accentColor;
  final VoidCallback onTap;

  const JobCompleteBtn({
    super.key,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  context.tr('worker_jobs.complete_job'),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppConstants.buttonHeightMd,
          decoration: BoxDecoration(
            color:        accentColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.done_all_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  context.tr('worker_jobs.complete_job'),
                  style: const TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
