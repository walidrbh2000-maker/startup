// lib/screens/worker_jobs/widgets/job_detail_fab_row.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_accept_decline_row.dart';
import 'job_complete_btn.dart';
import 'job_completed_badge.dart';
import 'job_loading_btn.dart';
import 'whatsapp_circle_btn.dart';

class JobDetailFabRow extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool         isLoading;
  final bool         isDark;
  final Color        accentColor;
  final String       userPhone;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onComplete;
  final VoidCallback? onStart;

  const JobDetailFabRow({
    super.key,
    required this.job,
    required this.isLoading,
    required this.isDark,
    required this.accentColor,
    required this.userPhone,
    required this.onAccept,
    required this.onDecline,
    required this.onComplete,
    this.onStart,
  });

  bool get _isTerminal =>
      job.status == ServiceStatus.completed ||
      job.status == ServiceStatus.cancelled ||
      job.status == ServiceStatus.declined;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMd,
        0,
        AppConstants.paddingMd,
        MediaQuery.of(context).padding.bottom + AppConstants.spacingSm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            WhatsAppCircleBtn(
              phone:    userPhone,
              isDark:   isDark,
              label:    context.tr('worker_jobs.chat_with_client'),
              size:     AppConstants.buttonHeightMd,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppConstants.animDurationShort,
                child: _buildPrimaryCta(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryCta(BuildContext context) {
    if (_isTerminal) {
      return JobCompletedBadge(
        key:    const ValueKey('terminal'),
        isDark: isDark,
      );
    }

    if (isLoading) {
      return JobLoadingBtn(
        key:         const ValueKey('loading'),
        accentColor: accentColor,
      );
    }

    switch (job.status) {
      case ServiceStatus.pending:
        return JobAcceptDeclineRow(
          key:       const ValueKey('pending'),
          onAccept:  onAccept,
          onDecline: onDecline,
        );

      case ServiceStatus.bidSelected:
        return _StartJobBtn(
          key:         const ValueKey('bidSelected'),
          accentColor: accentColor,
          onTap:       onStart,
          isDark:      isDark,
        );

      case ServiceStatus.accepted:
      case ServiceStatus.inProgress:
        return JobCompleteBtn(
          key:         const ValueKey('inProgress'),
          accentColor: accentColor,
          onTap:       onComplete,
        );

      default:
        return const SizedBox.shrink(key: ValueKey('noop'));
    }
  }
}

// ============================================================================
// _StartJobBtn
// ============================================================================

class _StartJobBtn extends StatelessWidget {
  final Color        accentColor;
  final VoidCallback? onTap;
  final bool          isDark;

  const _StartJobBtn({
    super.key,
    required this.accentColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  context.tr('worker_jobs.start_job'),
      child: SizedBox(
        width:  double.infinity,
        height: AppConstants.buttonHeightMd,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
          ),
          icon:  const Icon(Icons.play_arrow_rounded, size: 20),
          label: Text(
            context.tr('worker_jobs.start_job'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
