// lib/screens/worker_jobs/widgets/mission_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../providers/mission_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/localization.dart';
import 'complete_job_dialog.dart';

class MissionCard extends ConsumerWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;
  final Color accent;

  const MissionCard({
    super.key,
    required this.job,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state       = ref.watch(missionControllerProvider(job.id));
    final statusColor = AppTheme.getStatusColor(job.status, isDark);
    final isBidSelected = job.status == ServiceStatus.bidSelected;
    final isInProgress  = job.status == ServiceStatus.inProgress;

    // Show controller error via SnackBar once.
    ref.listen<MissionState>(
      missionControllerProvider(job.id),
      (_, next) {
        if (next.errorMessage != null) {
          ErrorHandler.showErrorSnackBar(
            context,
            context.tr(next.errorMessage!),
          );
          ref
              .read(missionControllerProvider(job.id).notifier)
              .clearError();
        }
      },
    );

    return Semantics(
      button: true,
      label: context.tr('worker_jobs.view_details'),
      child: GestureDetector(
        onTap: () => context.push(
          AppRoutes.workerJobDetail.replaceAll(':id', job.id),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSurface.withValues(alpha: 0.6)
                : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('services.${job.serviceType}'),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${context.tr('requests.client')}: ${job.userName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                          ),
                          if (job.agreedPrice != null)
                            Text(
                              '${job.agreedPrice!.toStringAsFixed(0)} ${context.tr('common.currency')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Text(
                        job.status.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),
                if (isBidSelected)
                  _ActionButton(
                    label: context.tr('worker_missions.start_job'),
                    color: accent,
                    isLoading: state.isLoading,
                    onTap: () => ref
                        .read(missionControllerProvider(job.id).notifier)
                        .startJob(job.id),
                  )
                else if (isInProgress)
                  _ActionButton(
                    label: context.tr('worker_missions.complete_job'),
                    color: AppTheme.acceptGreen,
                    isLoading: state.isLoading,
                    // Same flow as job detail: confirm + optional notes /
                    // final price — never one-tap close a paid job.
                    onTap: () async {
                      final result = await CompleteJobDialog.show(context);
                      if (result != null && context.mounted) {
                        await ref
                            .read(missionControllerProvider(job.id).notifier)
                            .completeJob(
                              requestId:   job.id,
                              workerNotes: result.notes,
                              finalPrice:  result.price,
                            );
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _ActionButton
// Internal widget — not extracted (used only by MissionCard).

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeightSm,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? color.withValues(alpha: 0.4) : color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
      ),
    );
  }
}
