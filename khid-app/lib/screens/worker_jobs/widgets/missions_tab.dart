// lib/screens/worker_jobs/widgets/missions_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'jobs_skeleton_loader.dart';
import 'mission_card.dart';
import 'tab_empty_state.dart';
import 'tab_error_state.dart';

// ============================================================================
// MISSIONS TAB — Tab 1 (My Active Missions)
// ============================================================================

class MissionsTab extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const MissionsTab({
    super.key,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerId = ref.watch(currentUserIdProvider);

    if (workerId == null) {
      return Center(child: Text(context.tr('common.not_logged_in')));
    }

    final jobsAsync = ref.watch(workerActiveJobsStreamProvider(workerId));

    return jobsAsync.when(
      loading: () => const JobsSkeletonLoader(),
      error: (_, __) => TabErrorState(isDark: isDark),
      data: (jobs) {
        if (jobs.isEmpty) {
          return TabEmptyState(
            isDark: isDark,
            icon: AppIcons.jobsOutlined,
            titleKey: 'worker_missions.no_missions',
            subtitleKey: 'worker_missions.no_missions_hint',
          );
        }
        return ListView.builder(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppConstants.paddingMd,
            AppConstants.spacingMd,
            AppConstants.paddingMd,
            AppConstants.spacingXl +
                MediaQuery.of(context).padding.bottom,
          ),
          itemCount: jobs.length,
          itemBuilder: (context, i) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppConstants.spacingMd),
              child: MissionCard(
                job: jobs[i],
                isDark: isDark,
                accent: accent,
              ),
            );
          },
        );
      },
    );
  }
}
