// lib/screens/worker_jobs/widgets/job_status_priority_row.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_pill_badge.dart';

class JobStatusPriorityRow extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;

  const JobStatusPriorityRow({
    super.key,
    required this.job,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(job.status, isDark);
    final priorityColor = job.priority == ServicePriority.urgent
        ? AppTheme.signOutRed
        : (isDark ? AppTheme.onlineGreen : AppTheme.greenTextLight);

    return Row(
      children: [
        JobPillBadge(
          icon: Icons.circle,
          iconSize: 8,
          label: _statusLabel(context, job.status),
          color: statusColor,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        JobPillBadge(
          icon: job.priority == ServicePriority.urgent
              ? Icons.flash_on_rounded
              : Icons.schedule_rounded,
          label: _priorityLabel(context, job.priority),
          color: priorityColor,
        ),
      ],
    );
  }

  String _statusLabel(BuildContext context, ServiceStatus s) {
    // ── Hybrid bid model statuses ─────────────────────────────────────────
    if (s == ServiceStatus.open) {
      return context.tr('worker_jobs.status_pending');
    }
    if (s == ServiceStatus.awaitingSelection) {
      return context.tr('worker_jobs.filter_in_progress');
    }
    if (s == ServiceStatus.bidSelected) {
      return context.tr('worker_jobs.status_accepted');
    }
    if (s == ServiceStatus.inProgress) {
      return context.tr('worker_jobs.status_in_progress');
    }
    if (s == ServiceStatus.completed) {
      return context.tr('worker_jobs.status_completed');
    }
    if (s == ServiceStatus.cancelled) {
      return context.tr('worker_jobs.status_cancelled');
    }
    if (s == ServiceStatus.expired) {
      return context.tr('worker_jobs.status_declined');
    }
    // ── Fallback — handles any legacy enum value (pending, accepted, declined)
    // if message_enums.dart has not yet been replaced.
    return s.displayName;
  }

  String _priorityLabel(BuildContext context, ServicePriority p) {
    return p == ServicePriority.urgent
        ? context.tr('worker_jobs.urgent_priority')
        : context.tr('worker_jobs.normal_priority');
  }
}

