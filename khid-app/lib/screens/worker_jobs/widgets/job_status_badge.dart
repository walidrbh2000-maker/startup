// lib/screens/worker_jobs/widgets/job_status_badge.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../utils/localization.dart';

class JobStatusBadge extends StatelessWidget {
  final ServiceStatus status;
  final Color         color;
  final bool          isDark;

  const JobStatusBadge({
    super.key,
    required this.status,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ServiceStatus.pending    => context.tr('worker_jobs.status_pending'),
      ServiceStatus.accepted   => context.tr('worker_jobs.status_accepted'),
      ServiceStatus.inProgress => context.tr('worker_jobs.status_in_progress'),
      ServiceStatus.completed  => context.tr('worker_jobs.status_completed'),
      ServiceStatus.cancelled  => context.tr('worker_jobs.status_cancelled'),
      ServiceStatus.declined   => context.tr('worker_jobs.status_declined'),
      _                        => status.displayName,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border:       Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:      color,
                  fontWeight: FontWeight.w700,
                  fontSize:   10,
                ),
          ),
        ],
      ),
    );
  }
}
