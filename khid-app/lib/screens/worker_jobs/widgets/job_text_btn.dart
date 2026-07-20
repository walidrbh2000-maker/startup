// lib/screens/worker_jobs/widgets/job_text_btn.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class JobTextBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const JobTextBtn({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

