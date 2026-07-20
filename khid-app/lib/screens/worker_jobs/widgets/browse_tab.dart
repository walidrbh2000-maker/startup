// lib/screens/worker_jobs/widgets/browse_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/available_requests_controller.dart';
import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'available_request_card.dart';
import 'browse_filter_bar.dart';
import 'jobs_skeleton_loader.dart';
import 'tab_error_state.dart';
import 'tab_empty_state.dart';

class BrowseTab extends ConsumerStatefulWidget {
  final bool isDark;
  final Color accent;

  const BrowseTab({
    super.key,
    required this.isDark,
    required this.accent,
  });

  @override
  ConsumerState<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<BrowseTab> {
  bool _hasLoggedView = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availableRequestsControllerProvider);
    final ctrl  = ref.read(availableRequestsControllerProvider.notifier);

    // Analytics: fire once when actual data is visible (not during loading).
    if (!state.isLoading && state.errorMessage == null && !_hasLoggedView) {
      _hasLoggedView = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(analyticsServiceProvider).logWorkerBrowseScreenViewed(
          availableRequestsCount: state.allRequests.length,
        );
      });
    }

    if (state.isLoading) {
      return const JobsSkeletonLoader();
    }

    if (state.errorMessage != null) {
      return TabErrorState(
        isDark: widget.isDark,
        onRetry: ctrl.refresh,
      );
    }

    return Column(
      children: [
        // Filter bar
        BrowseFilterBar(
          isDark: widget.isDark,
          accent: widget.accent,
          current: state.activeFilter,
          onChanged: (f) {
            ctrl.setFilter(f);
            // Analytics: wire here since we cannot modify the existing
            // controller without changing its signature (frozen contract).
            ref.read(analyticsServiceProvider).logBrowseFilterApplied(
              filter: f.name,
              resultsCount: state.filteredRequests.length,
            );
          },
        ),

        // Request list
        Expanded(
          child: state.filteredRequests.isEmpty
              ? TabEmptyState(
                  isDark: widget.isDark,
                  icon: AppIcons.requests,
                  titleKey: 'worker_browse.no_requests',
                  subtitleKey: 'worker_browse.no_requests_hint',
                )
              : ListView.builder(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppConstants.paddingMd,
                    AppConstants.spacingMd,
                    AppConstants.paddingMd,
                    AppConstants.spacingXl +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: state.filteredRequests.length,
                  itemBuilder: (context, i) {
                    final req = state.filteredRequests[i];
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppConstants.spacingMd),
                      child: AvailableRequestCard(
                        request: req,
                        isDark: widget.isDark,
                        accent: widget.accent,
                        hasMyBid: state.hasMyBid(req.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
