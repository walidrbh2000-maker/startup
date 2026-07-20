// lib/screens/service_request/widgets/my_requests_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../widgets/app_shimmer.dart';
import '../../../widgets/feature_empty_state.dart';
import '../../../utils/localization.dart';
import 'request_card.dart';

// ============================================================================
// FILTER ENUM
// ============================================================================

enum _RequestsFilter { all, active, done }

class MyRequestsPanel extends ConsumerStatefulWidget {
  final bool         isDark;
  final Color        accentColor;
  final VoidCallback onNewRequest;

  const MyRequestsPanel({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.onNewRequest,
  });

  @override
  ConsumerState<MyRequestsPanel> createState() => _MyRequestsPanelState();
}

class _MyRequestsPanelState extends ConsumerState<MyRequestsPanel> {
  _RequestsFilter _filter = _RequestsFilter.all;

  List<ServiceRequestEnhancedModel> _active = [];
  List<ServiceRequestEnhancedModel> _done   = [];
  bool _hasData = false;

  void _updateLists(List<ServiceRequestEnhancedModel> requests) {
    final active = requests
        .where((r) => r.status.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final done = requests
        .where((r) => r.status.isTerminal)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _active  = active;
      _done    = done;
      _hasData = true;
    });
  }

  List<ServiceRequestEnhancedModel> get _visible {
    return switch (_filter) {
      _RequestsFilter.all    => [..._active, ..._done],
      _RequestsFilter.active => _active,
      _RequestsFilter.done   => _done,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return _EmptyState(
        isDark:       widget.isDark,
        accentColor:  widget.accentColor,
        onNewRequest: widget.onNewRequest,
      );
    }

    final requestsAsync =
        ref.watch(userServiceRequestsStreamProvider(user.uid));

    ref.listen<AsyncValue<List<ServiceRequestEnhancedModel>>>(
      userServiceRequestsStreamProvider(user.uid),
      (_, next) {
        next.whenData(_updateLists);
      },
    );

    return requestsAsync.when(
      loading: () => const _LoadingSkeleton(),
      error: (_, __) => _EmptyState(
        isDark:       widget.isDark,
        accentColor:  widget.accentColor,
        onNewRequest: widget.onNewRequest,
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return _EmptyState(
            isDark:       widget.isDark,
            accentColor:  widget.accentColor,
            onNewRequest: widget.onNewRequest,
          );
        }

        final visible = _visible;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterBar(
              isDark:       widget.isDark,
              accentColor:  widget.accentColor,
              current:      _filter,
              onChanged:    (f) => setState(() => _filter = f),
            ),

            Expanded(
              child: visible.isEmpty
                  ? _EmptyFiltered(
                      isDark:      widget.isDark,
                      accentColor: widget.accentColor,
                    )
                  : ListView.builder(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        AppConstants.paddingMd,
                        AppConstants.spacingSm,
                        AppConstants.paddingMd,
                        AppConstants.spacingXl +
                            MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount:   visible.length,
                      itemBuilder: (context, i) {
                        final r = visible[i];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingSm),
                          child: RequestCard(
                            request:    r,
                            isDark:     widget.isDark,
                            accentColor: widget.accentColor,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// FILTER BAR
// ============================================================================

class _FilterBar extends StatelessWidget {
  final bool         isDark;
  final Color        accentColor;
  final _RequestsFilter current;
  final ValueChanged<_RequestsFilter> onChanged;

  const _FilterBar({
    required this.isDark,
    required this.accentColor,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      (_RequestsFilter.all,    context.tr('bids.filter_all')),
      (_RequestsFilter.active, context.tr('tracking.filter_active')),
      (_RequestsFilter.done,   context.tr('tracking.filter_done')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.spacingMd,
        AppConstants.paddingMd,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: chips.map((entry) {
          final (filter, label) = entry;
          final selected = current == filter;
          return Padding(
            padding: const EdgeInsetsDirectional.only(
                end: AppConstants.spacingSm),
            child: Semantics(
              button:   true,
              label:    label,
              selected: selected,
              child: GestureDetector(
                onTap: () => onChanged(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingTileInner,
                    vertical:   AppConstants.chipPaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withValues(alpha: 0.12)
                        : (isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: selected
                          ? accentColor.withValues(alpha: 0.5)
                          : (isDark
                              ? AppTheme.darkCardBorderOverlay
                              : AppTheme.lightCardBorderOverlay),
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? accentColor
                              : (isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATES
// ============================================================================

class _EmptyState extends StatelessWidget {
  final bool         isDark;
  final Color        accentColor;
  final VoidCallback onNewRequest;

  const _EmptyState({
    required this.isDark,
    required this.accentColor,
    required this.onNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureEmptyState(
      isDark:   isDark,
      icon:     AppIcons.requests,
      title:    context.tr('requests.no_requests'),
      subtitle: context.tr('request_form.subtitle'),
      action: Semantics(
        button: true,
        label:  context.tr('requests.new_request'),
        child: GestureDetector(
          onTap: onNewRequest,
          child: Container(
            height: AppConstants.buttonHeightMd,
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingLg),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.add, size: 18, color: Colors.white),
                const SizedBox(width: AppConstants.spacingXs),
                Text(
                  context.tr('requests.new_request'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  final bool  isDark;
  final Color accentColor;

  const _EmptyFiltered(
      {required this.isDark, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.tr('requests.no_requests'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
      ),
    );
  }
}

// ============================================================================
// LOADING SKELETON
// ============================================================================

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBone(
                width: 56, height: 9, radius: AppConstants.radiusXs),
            const SizedBox(height: AppConstants.spacingMd),
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: SkeletonBone(
                    width: double.infinity, height: 86,
                    radius: AppConstants.radiusLg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
