// lib/screens/worker_jobs/job_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/back_button.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../providers/worker_jobs_controller.dart';
import '../../providers/available_requests_controller.dart';
import 'widgets/job_location_map_sheet.dart';
import 'widgets/complete_job_dialog.dart';
import 'widgets/job_detail_hero_background.dart';
import 'widgets/job_status_priority_row.dart';
import 'widgets/job_section_card.dart';
import 'widgets/job_client_info_content.dart';
import 'widgets/job_service_details_content.dart';
import 'widgets/job_schedule_content.dart';
import 'widgets/job_pricing_content.dart';
import 'widgets/job_timeline_content.dart';
import 'widgets/job_media_gallery.dart';
import 'widgets/job_location_preview.dart';
import 'widgets/job_detail_fab_row.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Timer? _redirectTimer;

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  /// Schedule the auto-redirect to the worker jobs list. Idempotent while a
  /// timer is pending.
  void _scheduleRedirect() {
    if (_redirectTimer?.isActive ?? false) return;
    _redirectTimer = Timer(AppConstants.autoRedirectDelay, () {
      if (!mounted) return;
      context.go(AppRoutes.workerJobs);
    });
  }

  /// Cancel any pending auto-redirect — it must not fire on a live job screen.
  void _cancelRedirect() {
    _redirectTimer?.cancel();
    _redirectTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accentColor  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final jobsState    = ref.watch(workerJobsControllerProvider);
    final ctrl         = ref.read(workerJobsControllerProvider.notifier);
    final availableState = ref.watch(availableRequestsControllerProvider);

    final job =
        jobsState.allJobs.where((j) => j.id == widget.jobId).firstOrNull ??
        availableState.allRequests
            .where((j) => j.id == widget.jobId)
            .firstOrNull;

    // ── Job not found — cancellation message + auto-redirect ────────────────
    if (job == null) {
      _scheduleRedirect();

      return AppBackGuard(
        fallback: AppRoutes.workerJobs,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor:
                isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            leading: AppBarBackButton(
              onPressed: () => context.go(AppRoutes.workerJobs),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.cancel,
                    size: AppConstants.iconSizeLg2,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(height: AppConstants.spacingMdLg),
                  Text(
                    context.tr('worker_jobs.job_cancelled_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingSmMd),
                  Text(
                    context.tr('worker_jobs.job_cancelled_message'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    context.tr('worker_jobs.job_cancelled_redirect_hint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingXl),
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.workerJobs),
                    icon: const Icon(AppIcons.back),
                    label: Text(context.tr('worker_jobs.back_to_jobs')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    _cancelRedirect();

    final actionStatus = ref.watch(jobActionControllerProvider(job.id));
    final isLoading    = actionStatus.isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // Deep-link target (bid_accepted push, cold start) — stack may be
      // empty; back falls back to the jobs list instead of dead-ending.
      child: AppBackGuard(
        fallback: AppRoutes.workerJobs,
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: AppConstants.heroExpandedHeight,
                pinned:         true,
                stretch:        true,
                backgroundColor:
                    isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                leading: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSm),
                  child: Semantics(
                    button: true,
                    label:  context.tr('common.back'),
                    child: GestureDetector(
                      onTap: () =>
                          appBack(context, fallback: AppRoutes.workerJobs),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.back,
                          color: isDark ? Colors.white : Colors.black,
                          size:  AppConstants.iconSizeSm,
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(
                    AppConstants.paddingXl + AppConstants.paddingLg, // 56dp — leading clearance
                    0,
                    AppConstants.paddingMd,                          // 16dp
                    AppConstants.spacingSm + AppConstants.spacingXs, // 12dp
                  ),
                  title: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize:   AppConstants.fontSizeLg,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: JobDetailHeroBackground(
                    job:         job,
                    isDark:      isDark,
                    accentColor: accentColor,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    AppConstants.paddingXl +
                        MediaQuery.paddingOf(context).bottom +
                        AppConstants.fabClearance,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JobStatusPriorityRow(job: job, isDark: isDark),
                      const SizedBox(height: AppConstants.spacingLg),

                      JobSectionCard(
                        title:     context.tr('worker_jobs.client_info'),
                        icon:      AppIcons.profile,
                        iconColor: accentColor,
                        isDark:    isDark,
                        child:     JobClientInfoContent(job: job, isDark: isDark),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      JobSectionCard(
                        title:     context.tr('worker_jobs.service_details'),
                        icon:      AppTheme.getProfessionIcon(job.serviceType),
                        iconColor: accentColor,
                        isDark:    isDark,
                        child: JobServiceDetailsContent(job: job, isDark: isDark),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      JobSectionCard(
                        title:     context.tr('worker_jobs.description'),
                        icon:      AppIcons.description,
                        iconColor: accentColor,
                        isDark:    isDark,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacingMd),
                          child: Text(
                            job.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  height: 1.6,
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      if (job.mediaUrls.isNotEmpty) ...[
                        JobSectionCard(
                          title:     context.tr('worker_jobs.media_gallery'),
                          icon:      AppIcons.media,
                          iconColor: accentColor,
                          isDark:    isDark,
                          child: JobMediaGallery(
                            urls:        job.mediaUrls,
                            isDark:      isDark,
                            accentColor: accentColor,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                      ],

                      JobSectionCard(
                        title:     context.tr('worker_jobs.schedule'),
                        icon:      AppIcons.calendarToday,
                        iconColor: accentColor,
                        isDark:    isDark,
                        child: JobScheduleContent(job: job, isDark: isDark),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),

                      JobSectionCard(
                        title:     context.tr('worker_jobs.location'),
                        icon:      AppIcons.location,
                        iconColor: accentColor,
                        isDark:    isDark,
                        child: JobLocationPreview(
                          job:         job,
                          isDark:      isDark,
                          accentColor: accentColor,
                          onOpen: () => JobLocationMapSheet.show(
                            context,
                            latitude:   job.userLatitude,
                            longitude:  job.userLongitude,
                            address:    job.userAddress,
                            clientName: job.userName,
                          ),
                        ),
                      ),

                      if (job.estimatedPrice != null || job.finalPrice != null) ...[
                        const SizedBox(height: AppConstants.spacingMd),
                        JobSectionCard(
                          title:     context.tr('worker_jobs.pricing'),
                          icon:      AppIcons.payments,
                          iconColor: accentColor,
                          isDark:    isDark,
                          child:     JobPricingContent(job: job, isDark: isDark),
                        ),
                      ],

                      const SizedBox(height: AppConstants.spacingMd),
                      JobSectionCard(
                        title:     context.tr('worker_jobs.timeline'),
                        icon:      AppIcons.timeline,
                        iconColor: accentColor,
                        isDark:    isDark,
                        child: JobTimelineContent(job: job, isDark: isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: JobDetailFabRow(
            job:         job,
            isLoading:   isLoading,
            isDark:      isDark,
            accentColor: accentColor,
            userPhone:   job.userPhone,
            onAccept:    () => ctrl.acceptJob(job.id),
            onStart:     () => ctrl.startJob(job.id),
            onDecline:   () => _confirmDecline(context, ctrl, job.id),
            onComplete:  () => _showCompleteDialog(context, ctrl, job.id),
          ),
        ),
      ),
    );
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
    WorkerJobsController ctrl,
    String jobId,
  ) async {
    final result = await CompleteJobDialog.show(context);
    if (result != null && mounted) {
      await ctrl.completeJob(jobId,
          notes: result.notes, finalPrice: result.price);
    }
  }

  Future<void> _confirmDecline(
    BuildContext context,
    WorkerJobsController ctrl,
    String jobId,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        ),
        title:   Text(context.tr('worker_jobs.decline_confirm_title')),
        content: Text(context.tr('worker_jobs.decline_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppTheme.signOutRed
                    : AppTheme.lightError),
            child: Text(context.tr('worker_jobs.decline_job')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) ctrl.declineJob(jobId);
  }
}
