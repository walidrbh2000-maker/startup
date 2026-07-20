// lib/screens/worker_jobs/widgets/job_card.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'job_action_buttons.dart';
import 'job_card_header.dart';
import 'job_location_map_sheet.dart';
import 'job_media_viewer.dart';
import 'job_meta_chip.dart';
import 'job_urgent_badge.dart';

class JobCard extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final JobActionStatus             actionStatus;
  final String?                     actionError;
  final VoidCallback                onAccept;
  final VoidCallback                onComplete;
  final VoidCallback                onDecline;
  final VoidCallback                onChat;
  final VoidCallback                onViewDetails;
  final double?                     workerLat;
  final double?                     workerLng;

  const JobCard({
    super.key,
    required this.job,
    required this.actionStatus,
    this.actionError,
    required this.onAccept,
    required this.onComplete,
    required this.onDecline,
    required this.onChat,
    required this.onViewDetails,
    this.workerLat,
    this.workerLng,
  });

  double? _distanceKm() {
    if (workerLat == null || workerLng == null) return null;
    final distM = Geolocator.distanceBetween(
      workerLat!, workerLng!, job.userLatitude, job.userLongitude,
    );
    return distM / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accentColor  = isDark ? AppTheme.darkAccent  : AppTheme.lightAccent;
    final statusColor  = AppTheme.getStatusColor(job.status, isDark);
    final serviceColor = AppTheme.getProfessionColor(job.serviceType, isDark);
    final distance     = _distanceKm();
    final isLoading    = actionStatus == JobActionStatus.loading;
    final isSuccess    = actionStatus == JobActionStatus.success;
    final isError      = actionStatus == JobActionStatus.error;

    return Semantics(
      button: true,
      label: '${job.title}, ${job.userName}, ${_statusLabel(context, job.status)}',
      child: GestureDetector(
        onTap: isLoading ? null : onViewDetails,
        child: AnimatedContainer(
          duration: AppConstants.animDurationShort,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: isError
                  ? AppTheme.signOutRed.withValues(alpha: 0.4)
                  : isSuccess
                      ? AppTheme.onlineGreen.withValues(alpha: 0.4)
                      : job.priority == ServicePriority.urgent
                          ? AppTheme.signOutRed.withValues(alpha: 0.3)
                          : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: isError || isSuccess ? 1.5 : 0.5,
            ),
          ),
          child: Stack(
            children: [
              // Status accent bar
              Positioned(
                left: 0, top: 16, bottom: 16,
                child: Container(
                  width: AppConstants.accentBarWidth,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topRight:    Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JobCardHeader(
                      job:          job,
                      serviceColor: serviceColor,
                      statusColor:  statusColor,
                      accentColor:  accentColor,
                      isDark:       isDark,
                    ),

                    const SizedBox(height: AppConstants.spacingSm),

                    Text(
                      job.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                            height: 1.45,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppConstants.spacingSm),

                    Wrap(
                      spacing:    AppConstants.spacingXs,
                      runSpacing: AppConstants.spacingXs,
                      children: [
                        JobMetaChip(
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat('MMM d, HH:mm').format(
                            DateTime(
                              job.scheduledDate.year,
                              job.scheduledDate.month,
                              job.scheduledDate.day,
                              job.scheduledTime.hour,
                              job.scheduledTime.minute,
                            ),
                          ),
                          isDark: isDark,
                          color:  accentColor,
                        ),

                        if (distance != null)
                          JobMetaChip(
                            icon:   Icons.near_me_rounded,
                            label:  distance < 1
                                ? '${(distance * 1000).round()} m'
                                : '${distance.toStringAsFixed(1)} km',
                            isDark: isDark,
                            color:  accentColor,
                          ),

                        if (job.mediaUrls.isNotEmpty)
                          JobMetaChip(
                            icon:   Icons.perm_media_rounded,
                            label:  '${job.mediaUrls.length}',
                            isDark: isDark,
                            color:  accentColor,
                          ),

                        if (job.priority == ServicePriority.urgent)
                          JobUrgentBadge(isDark: isDark),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (isError && actionError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:        AppTheme.signOutRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(AppIcons.error, size: 14,
                                color: AppTheme.signOutRed),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                actionError!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                        color: isDark
                                            ? AppTheme.signOutRed
                                            : AppTheme.lightError),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    JobActionButtons(
                      job:         job,
                      isLoading:   isLoading,
                      isSuccess:   isSuccess,
                      isDark:      isDark,
                      accentColor: accentColor,
                      onAccept:    onAccept,
                      onComplete:  onComplete,
                      onDecline:   onDecline,
                      onLocation: () => JobLocationMapSheet.show(
                        context,
                        latitude:   job.userLatitude,
                        longitude:  job.userLongitude,
                        address:    job.userAddress,
                        clientName: job.userName,
                      ),
                      onMedia: job.mediaUrls.isNotEmpty
                          ? () => JobMediaViewer.show(context,
                              mediaUrls: job.mediaUrls)
                          : null,
                    ),
                  ],
                ),
              ),

              if (isLoading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    child: Container(
                      color: (isDark ? Colors.black : Colors.white)
                          .withValues(alpha: 0.40),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:       accentColor,
                        ),
                      ),
                    ),
                  ),
                ),

              if (isSuccess)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    child: Container(
                      color: AppTheme.onlineGreen.withValues(alpha: 0.12),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.onlineGreen,
                          size:  36,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:    return context.tr('worker_jobs.status_pending');
      case ServiceStatus.accepted:   return context.tr('worker_jobs.status_accepted');
      case ServiceStatus.inProgress: return context.tr('worker_jobs.status_in_progress');
      case ServiceStatus.completed:  return context.tr('worker_jobs.status_completed');
      case ServiceStatus.cancelled:  return context.tr('worker_jobs.status_cancelled');
      case ServiceStatus.declined:   return context.tr('worker_jobs.status_declined');
      default:                       return '';
    }
  }
}
