// lib/screens/worker_jobs/worker_jobs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/subscription_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/feature_error_state.dart';
import '../subscription/widgets/subscription_locked_view.dart';
import 'widgets/browse_tab.dart';
import 'widgets/missions_tab.dart';
import 'widgets/my_bids_tab.dart';

// Subscription gate: worker earning-features (browse/missions/bids) are locked
// behind an active visibility subscription. An unsubscribed worker still uses
// the app fully as a client via the other tabs — only this surface is gated.

class WorkerJobsScreen extends ConsumerStatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  ConsumerState<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends ConsumerState<WorkerJobsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    // Subscription gate. While the user doc loads, show a spinner rather than
    // flashing the paywall to an already-subscribed worker.
    final userDoc = ref.watch(currentUserDocProvider);
    final Widget body = userDoc.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // A transient load failure is NOT "not subscribed" — showing the
      // paywall to a paying worker on a network blip reads as a scam.
      error: (_, __) => FeatureErrorState(
        isDark:     isDark,
        errorTitle: context.tr('errors.generic'),
        onRetry:    () => ref.invalidate(currentUserDocProvider),
        retryLabel: context.tr('common.retry'),
      ),
      data: (u) => (u?.isSubscribed ?? false)
          ? Column(
              children: [
                _JobsHeader(
                  isDark: isDark,
                  accent: accent,
                  tabController: _tabController,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      BrowseTab(isDark: isDark, accent: accent),
                      MissionsTab(isDark: isDark, accent: accent),
                      MyBidsTab(isDark: isDark, accent: accent),
                    ],
                  ),
                ),
              ],
            )
          : const SubscriptionLockedView(),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        body: SafeArea(child: body),
      ),
    );
  }
}

// ============================================================================
// _JobsHeader
// ============================================================================

class _JobsHeader extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final TabController tabController;

  const _JobsHeader({
    required this.isDark,
    required this.accent,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMd,
            AppConstants.paddingMd,
            AppConstants.paddingMd,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('nav.jobs'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: tabController,
          indicatorColor: accent,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor:
              isDark ? AppTheme.darkText : AppTheme.lightText,
          unselectedLabelColor: isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
          labelStyle: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: context.tr('worker_browse.tab_browse')),
            Tab(text: context.tr('worker_missions.tab_missions')),
            Tab(text: context.tr('worker_my_bids.tab_bids')),
          ],
        ),
      ],
    );
  }
}
