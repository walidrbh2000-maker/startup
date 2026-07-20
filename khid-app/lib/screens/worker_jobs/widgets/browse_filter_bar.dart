// lib/screens/worker_jobs/widgets/browse_filter_bar.dart

import 'package:flutter/material.dart';

import '../../../providers/available_requests_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// BROWSE FILTER BAR

class BrowseFilterBar extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final AvailableRequestsFilter current;
  final ValueChanged<AvailableRequestsFilter> onChanged;

  const BrowseFilterBar({
    super.key,
    required this.isDark,
    required this.accent,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      AvailableRequestsFilter.all,
      AvailableRequestsFilter.urgent,
      AvailableRequestsFilter.highBudget,
      AvailableRequestsFilter.noBids,
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
        children: items.map((f) {
          final selected = f == current;
          return Padding(
            padding: const EdgeInsetsDirectional.only(
                end: AppConstants.spacingSm),
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppConstants.chipPaddingH,
                  vertical: AppConstants.chipPaddingV,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.12)
                      : (isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: selected
                        ? accent.withValues(alpha: 0.5)
                        : (isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder),
                  ),
                ),
                child: Text(
                  f.label(context.tr),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? (isDark ? AppTheme.darkAccentText : accent)
                            : (isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
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
