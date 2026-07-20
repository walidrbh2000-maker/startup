// lib/screens/home/widgets/home_worker_section.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../models/worker_model.dart';
import '../../../providers/worker_home_controller.dart';
import '../../../providers/worker_jobs_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/app_shimmer.dart';

// ── Local constants ────────────────────────────────────────────────────────────
const double _kSectionDividerH = 0.5;
const int    _kMaxNearbyJobs   = 3;

// ============================================================================
// HOME WORKER SECTION
// ============================================================================

class HomeWorkerSection extends ConsumerWidget {
  const HomeWorkerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final workerState = ref.watch(workerHomeControllerProvider);
    final jobsState   = ref.watch(workerJobsControllerProvider);

    if (workerState.isWorkerLoading) {
      return const _WorkerSectionSkeleton();
    }

    if (workerState.isWorkerError) {
      return _WorkerSectionError(
        isDark:  isDark,
        onRetry: () =>
            ref.read(workerHomeControllerProvider.notifier).refresh(),
      );
    }

    final worker = workerState.worker;
    if (worker == null) return const SizedBox.shrink();

    final isOnline = workerState.isOnline;
    final rating   = worker.averageRating;
    final pending  = jobsState.jobs
        .where((j) => j.status == ServiceStatus.open)
        .take(_kMaxNearbyJobs)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLg),
          child: Container(
            height: _kSectionDividerH,
            color:  isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),

        const SizedBox(height: AppConstants.spacingMd),

        _AvailabilityToggle(
          isDark:   isDark,
          isOnline: isOnline,
          onToggle: () {
            HapticFeedback.mediumImpact();
            ref
                .read(workerHomeControllerProvider.notifier)
                .toggleOnlineStatus();
          },
        ),

        const SizedBox(height: AppConstants.spacingSm),

        _UsageCard(isDark: isDark, worker: worker, isOnline: isOnline),

        const SizedBox(height: AppConstants.spacingSm),

        _RoiStrip(
          isDark:       isDark,
          rating:       rating,
          monthlyCount: jobsState.jobs.length,
        ),

        const SizedBox(height: AppConstants.spacingSm),

        _DemandBar(
          isDark:       isDark,
          pendingCount: pending.length,
        ),

        if (isOnline && pending.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg),
            child: Text(
              context.tr('worker_home.nearby_jobs'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight:    FontWeight.w700,
                    color:         isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          ...pending.map(
            (job) => _NearbyJobTile(job: job, isDark: isDark),
          ),
        ],

        const SizedBox(height: AppConstants.spacingMd),
      ],
    );
  }
}

// ── ① Availability toggle ─────────────────────────────────────────────────────

class _AvailabilityToggle extends StatelessWidget {
  final bool         isDark;
  final bool         isOnline;
  final VoidCallback onToggle;

  const _AvailabilityToggle({
    required this.isDark,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final onColor  = AppTheme.onlineGreen;
    final offColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final dotColor = isOnline ? onColor : offColor;
    final subtext  = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical:   AppConstants.spacingMd,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isOnline
                  ? onColor.withValues(alpha: 0.30)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width:  AppConstants.statusDotSize,
                height: AppConstants.statusDotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline
                          ? context.tr('worker_home.status_online')
                          : context.tr('worker_home.status_offline'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color:      isOnline
                                ? (isDark
                                    ? AppTheme.onlineGreen
                                    : AppTheme.greenTextLight)
                                : (isDark
                                    ? AppTheme.darkText
                                    : AppTheme.lightText),
                          ),
                    ),
                    Text(
                      isOnline
                          ? context.tr('worker_home.online_description')
                          : context.tr('worker_home.offline_description'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: subtext,
                          ),
                    ),
                  ],
                ),
              ),
              _ToggleSwitch(isOn: isOnline, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool isOn;
  final bool isDark;
  const _ToggleSwitch({required this.isOn, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final onColor       = AppTheme.onlineGreen;
    final offTrackColor = isDark
        ? AppTheme.darkSurfaceVariant
        : AppTheme.lightSurfaceVariant;

    return AnimatedContainer(
      duration: AppConstants.animDurationMicro,
      width:  AppConstants.toggleTrackW,
      height: AppConstants.toggleTrackH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        color: isOn ? onColor : offTrackColor,
      ),
      child: AnimatedAlign(
        duration: AppConstants.animDurationMicro,
        curve:    Curves.easeInOut,
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width:  AppConstants.toggleThumbSize,
          height: AppConstants.toggleThumbSize,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn
                ? Theme.of(context).colorScheme.surface
                : (isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText),
          ),
        ),
      ),
    );
  }
}

// ── ② ROI metrics strip ────────────────────────────────────────────────────────

class _RoiStrip extends StatelessWidget {
  final bool   isDark;
  final double rating;
  final int    monthlyCount;

  const _RoiStrip({
    required this.isDark,
    required this.rating,
    required this.monthlyCount,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccentText : AppTheme.lightAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Row(
        children: [
          _RoiCard(
            isDark:  isDark,
            value:   '$monthlyCount',
            label:   context.tr('worker_home.roi_requests'),
            accent:  accent,
          ),
          const SizedBox(width: AppConstants.spacingXs),
          _RoiCard(
            isDark:  isDark,
            value:   rating.toStringAsFixed(1),
            label:   context.tr('worker_home.roi_rating'),
            accent:  accent,
          ),
          const SizedBox(width: AppConstants.spacingXs),
          // ponytail: rank is a hardcoded placeholder — wire real ranking data
          // or drop this card before launch.
          _RoiCard(
            isDark:  isDark,
            value:   '#1',
            label:   context.tr('worker_home.roi_rank'),
            accent:  accent,
          ),
        ],
      ),
    );
  }
}

class _RoiCard extends StatelessWidget {
  final bool   isDark;
  final String value;
  final String label;
  final Color  accent;

  const _RoiCard({
    required this.isDark,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical:   AppConstants.spacingSm,
        ),
        decoration: BoxDecoration(
          color:        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      accent,
                  ),
            ),
            SizedBox(height: AppConstants.spacingXxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    height: 1.2,
                  ),
              textAlign: TextAlign.center,
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── ③ Demand bar ─────────────────────────────────────────────────────────────

class _DemandBar extends StatelessWidget {
  final bool isDark;
  final int  pendingCount;

  const _DemandBar({required this.isDark, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final isHigh   = pendingCount >= 4;
    final isMedium = pendingCount >= 1 && pendingCount < 4;
    final barColor = isHigh
        ? AppTheme.recordingRed
        : isMedium
            ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
            : (isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText);
    final fillRatio = (pendingCount / 8.0).clamp(0.0, 1.0);
    final label = isHigh
        ? context.tr('worker_home.demand_high')
        : isMedium
            ? context.tr('worker_home.demand_medium')
            : context.tr('worker_home.demand_low');

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        decoration: BoxDecoration(
          color:        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('worker_home.demand_title'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical:   AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color:        barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      isMedium && isDark
                              ? AppTheme.darkAccentText
                              : barColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.strengthBarRadius),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    color:  isDark
                        ? AppTheme.darkBorder
                        : AppTheme.lightBorder,
                  ),
                  FractionallySizedBox(
                    widthFactor: fillRatio,
                    child: Container(height: 4, color: barColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              '$pendingCount ${context.tr('worker_home.demand_sub')}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ④ Nearby job tile ─────────────────────────────────────────────────────────

class _NearbyJobTile extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool                         isDark;

  const _NearbyJobTile({required this.job, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final surface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        0,
        AppConstants.paddingLg,
        AppConstants.spacingXs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMd,
          vertical:   AppConstants.spacingMd,
        ),
        decoration: BoxDecoration(
          color:        surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: accent.withValues(alpha: 0.20),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width:  AppConstants.iconContainerMd,
              height: AppConstants.iconContainerMd,
              decoration: BoxDecoration(
                color:        accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Icon(AppIcons.requests, color: accent, size: 16),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.serviceType.isNotEmpty
                        ? job.serviceType
                        : context.tr('home.filter_all'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    job.userAddress.isNotEmpty
                        ? job.userAddress
                        : context.tr('worker_home.location_unknown'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSm,
                vertical:   AppConstants.spacingXxs,
              ),
              decoration: BoxDecoration(
                color:        AppTheme.recordingRed,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Text(
                context.tr('worker_home.badge_new'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:      Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ⑤ Loading skeleton ────────────────────────────────────────────────────────

class _WorkerSectionSkeleton extends StatelessWidget {
  const _WorkerSectionSkeleton();

  static Widget _bone({double? width, required double height}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
        child: SkeletonBone(
          width:  width ?? double.infinity,
          height: height,
          radius: AppConstants.radiusMd,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingLg,
          AppConstants.spacingMd,
          AppConstants.paddingLg,
          AppConstants.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Divider
            const SkeletonBone(
                width: double.infinity, height: _kSectionDividerH, radius: 1),
            const SizedBox(height: AppConstants.spacingMd),
            // Toggle card
            _bone(height: AppConstants.buttonHeight),
            const SizedBox(height: AppConstants.spacingSm),
            Row(
              children: [
                Expanded(child: _bone(height: 64)),
                const SizedBox(width: AppConstants.spacingXs),
                Expanded(child: _bone(height: 64)),
                const SizedBox(width: AppConstants.spacingXs),
                Expanded(child: _bone(height: 64)),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            // Demand bar
            _bone(height: 80),
            const SizedBox(height: AppConstants.spacingMd),
          ],
        ),
      ),
    );
  }
}

// ── ⑥ Error state ─────────────────────────────────────────────────────────────

class _WorkerSectionError extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onRetry;

  const _WorkerSectionError({
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final subtext = isDark
        ? AppTheme.darkSecondaryText
        : AppTheme.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppConstants.spacingLg),
          Icon(
            AppIcons.warning,
            size:  AppConstants.iconSizeLg,
            color: subtext,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            context.tr('worker_home.load_error'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtext,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.tr('common.retry')),
          ),
          const SizedBox(height: AppConstants.spacingLg),
        ],
      ),
    );
  }
}

// ── ⑦ Usage / online-time card ─────────────────────────────────────────────────
//
// Shows the worker's metered online time for TODAY as a progress bar that
// fills while the worker is online and resets at 00:00 (the model's
// usageSecondsAt() zeroes any bucket from a previous day and clips the live
// session at local midnight). Ticks live (1 Hz) while online; the counter
// freezes when offline — exactly what the switch controls.
//
// Bar scale: the pack's daily quota (basic 5 h, pro 10 h) or the full 24 h
// day for unlimited packs. The backend enforces the same contract
// (subscriptionVisibilityFilter): quota exhausted or Basic on a weekend →
// hidden from search/map until 00:00. The captions below the bar tell the
// worker exactly which state they are in.

String _formatUsageClock(int seconds, {required bool withSeconds}) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return withSeconds
      ? '${two(h)}:${two(m)}:${two(s)}'
      : '${two(h)}:${two(m)}';
}

/// "5 h" / "9 h 30" — compact quota label.
String _formatHours(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

class _UsageCard extends StatefulWidget {
  final bool        isDark;
  final WorkerModel worker;
  final bool        isOnline;

  const _UsageCard({
    required this.isDark,
    required this.worker,
    required this.isOnline,
  });

  @override
  State<_UsageCard> createState() => _UsageCardState();
}

class _UsageCardState extends State<_UsageCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_UsageCard old) {
    super.didUpdateWidget(old);
    if (old.isOnline != widget.isOnline) _syncTicker();
  }

  // Only run a timer while online — no wasted rebuilds when the counter is frozen.
  void _syncTicker() {
    _ticker?.cancel();
    if (widget.isOnline) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final online = widget.isOnline;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final onColor = AppTheme.onlineGreen;
    final subtext = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final track = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final seconds = widget.worker.usageSecondsAt(DateTime.now());
    final quota   = widget.worker.dailyQuotaSeconds; // null = unlimited
    final scale   = quota ?? 24 * 3600;
    final ratio   = (seconds / scale).clamp(0.0, 1.0);
    final over    = widget.worker.quotaExhaustedAt(DateTime.now());

    // Bar color: green while filling (online), amber once past the quota,
    // neutral accent when frozen offline.
    final barColor = over
        ? (isDark ? AppTheme.warningAmber : AppTheme.amberTextLight)
        : online
            ? onColor
            : accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        decoration: BoxDecoration(
          color:        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: online
                ? onColor.withValues(alpha: 0.30)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width:  AppConstants.iconContainerMd,
                  height: AppConstants.iconContainerMd,
                  decoration: BoxDecoration(
                    color:        accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(Icons.timer_outlined, color: accent, size: 18),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('worker_home.usage_title'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: subtext,
                            ),
                      ),
                      Text(
                        _formatUsageClock(seconds, withSeconds: online),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight:       FontWeight.w800,
                              fontFeatures:     const [FontFeature.tabularFigures()],
                              color:            online
                                  ? (isDark
                                      ? AppTheme.onlineGreen
                                      : AppTheme.greenTextLight)
                                  : (isDark ? AppTheme.darkText : AppTheme.lightText),
                            ),
                      ),
                    ],
                  ),
                ),
                // Live status pill.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                    vertical:   AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: (online ? onColor : subtext).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: online ? onColor : subtext,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Text(
                        online
                            ? context.tr('worker_home.usage_running')
                            : context.tr('worker_home.usage_paused'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:      online
                                  ? (isDark
                                      ? AppTheme.onlineGreen
                                      : AppTheme.greenTextLight)
                                  : subtext,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ── Daily fill bar — resets at 00:00 ────────────────────────────
            Semantics(
              label: context.tr('worker_home.usage_title'),
              value: _formatUsageClock(seconds, withSeconds: false),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: ratio),
                  duration: AppConstants.animDurationMicro,
                  curve: Curves.easeOut,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: track.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingXs),

            // Caption: quota (or unlimited) · resets at midnight.
            Row(
              children: [
                Expanded(
                  child: Text(
                    quota == null
                        ? context.tr('worker_home.usage_unlimited')
                        : context
                            .tr('worker_home.usage_quota')
                            .replaceFirst('{hours}', _formatHours(quota)),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: subtext),
                  ),
                ),
                Text(
                  context.tr('worker_home.usage_resets'),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: subtext),
                ),
              ],
            ),

            // Visibility warning — mirrors the server-side gate so the worker
            // is never surprised: quota exhausted → hidden until 00:00.
            if (over) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Icon(
                    Icons.visibility_off_rounded,
                    size: 14,
                    color: isDark
                        ? AppTheme.warningAmber
                        : AppTheme.amberTextLight,
                  ),
                  const SizedBox(width: AppConstants.spacingXs),
                  Expanded(
                    child: Text(
                      context.tr('worker_home.usage_quota_reached'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.warningAmber
                                : AppTheme.amberTextLight,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
