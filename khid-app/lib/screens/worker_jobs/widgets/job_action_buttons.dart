// lib/screens/worker_jobs/widgets/job_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_icon_btn.dart';
import 'job_text_btn.dart';
import 'job_primary_btn.dart';
import 'whatsapp_circle_btn.dart';

class JobActionButtons extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool      isLoading;
  final bool      isSuccess;
  final bool      isDark;
  final Color     accentColor;
  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onDecline;
  final VoidCallback onLocation;
  final VoidCallback? onMedia;

  /// Called when the worker taps "Start Job" from the action bar in
  /// bidSelected status. Nullable; pass null to show the button disabled.
  final VoidCallback? onStart;

  const JobActionButtons({
    super.key,
    required this.job,
    required this.isLoading,
    required this.isSuccess,
    required this.isDark,
    required this.accentColor,
    required this.onAccept,
    required this.onComplete,
    required this.onDecline,
    required this.onLocation,
    required this.onMedia,
    this.onStart,
  });

  bool get _isCompleted =>
      job.status == ServiceStatus.completed ||
      job.status == ServiceStatus.cancelled ||
      job.status == ServiceStatus.declined;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── WhatsApp contact button ───────────────────────────────────
        WhatsAppCircleBtn(
          phone:    job.userPhone,
          isDark:   isDark,
          disabled: isLoading,
          label:    context.tr('worker_jobs.chat_with_client'),
          size:     40,
        ),
        const SizedBox(width: AppConstants.spacingXs),

        // ── Location ──────────────────────────────────────────────────
        JobIconBtn(
          icon:   AppIcons.location,
          label:  context.tr('worker_jobs.view_location'),
          color:  accentColor,
          isDark: isDark,
          onTap:  isLoading ? null : onLocation,
        ),

        // ── Media (optional) ──────────────────────────────────────────
        if (onMedia != null) ...[
          const SizedBox(width: AppConstants.spacingXs),
          JobIconBtn(
            icon:   Icons.perm_media_rounded,
            label:  context.tr('worker_jobs.view_media'),
            color:  accentColor,
            isDark: isDark,
            onTap:  isLoading ? null : onMedia,
          ),
        ],

        const Spacer(),

        // ── Status-based primary actions ──────────────────────────────
        if (!_isCompleted && !isSuccess) ...[
          if (job.status == ServiceStatus.pending) ...[
            JobTextBtn(
              label: context.tr('worker_jobs.decline_job'),
              color: isDark ? AppTheme.signOutRed : AppTheme.lightError,
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onDecline();
                    },
            ),
            const SizedBox(width: AppConstants.spacingXs),
            JobPrimaryBtn(
              label: context.tr('worker_jobs.accept_job'),
              icon:  Icons.check_rounded,
              color: AppTheme.onlineGreen,
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onAccept();
                    },
            ),

          // bidSelected: the client picked this worker's bid — show "Start Job".
          ] else if (job.status == ServiceStatus.bidSelected) ...[
            JobPrimaryBtn(
              label: context.tr('worker_jobs.start_job'),
              icon:  Icons.play_arrow_rounded,
              color: accentColor,
              onTap: isLoading
                  ? null
                  : onStart != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          onStart!();
                        }
                      : null,
            ),

          ] else if (job.status == ServiceStatus.accepted ||
              job.status == ServiceStatus.inProgress) ...[
            JobPrimaryBtn(
              label: context.tr('worker_jobs.complete_job'),
              icon:  Icons.done_all_rounded,
              color: accentColor,
              onTap: isLoading ? null : onComplete,
            ),
          ],
        ],
      ],
    );
  }
}
