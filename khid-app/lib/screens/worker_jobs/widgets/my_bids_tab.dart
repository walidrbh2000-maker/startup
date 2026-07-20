// lib/screens/worker_jobs/widgets/my_bids_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'jobs_skeleton_loader.dart';
import 'my_bid_card.dart';
import 'tab_empty_state.dart';
import 'tab_error_state.dart';

// ============================================================================
// MY BIDS TAB — Tab 2 (My Submitted Bids)
// ============================================================================

class MyBidsTab extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const MyBidsTab({
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

    final bidsAsync = ref.watch(workerBidsStreamProvider(workerId));

    return bidsAsync.when(
      loading: () => const JobsSkeletonLoader(),
      error: (_, __) => TabErrorState(isDark: isDark),
      data: (bids) {
        if (bids.isEmpty) {
          return TabEmptyState(
            isDark: isDark,
            icon: AppIcons.bidOutlined,
            titleKey: 'worker_my_bids.no_bids',
            subtitleKey: 'worker_my_bids.no_bids_hint',
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
          itemCount: bids.length,
          itemBuilder: (context, i) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppConstants.spacingMd),
              child: MyBidCard(
                bid: bids[i],
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
