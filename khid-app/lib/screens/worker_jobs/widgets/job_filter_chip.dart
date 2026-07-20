// lib/screens/worker_jobs/widgets/job_filter_chip.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobFilterChip extends StatelessWidget {
  final String     label;
  final int        count;
  final bool       isActive;
  final bool       isDark;
  final Color      accentColor;
  final VoidCallback onTap;

  const JobFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.isActive,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button:   true,
      label:    '$label ($count)',
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve:    Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withValues(alpha: 0.18)
                : (isDark
                    ? AppTheme.darkSurfaceHalf
                    : Colors.white.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isActive
                  ? accentColor.withValues(alpha: 0.7)
                  : (isDark
                      ? AppTheme.darkCardBorderOverlay
                      : AppTheme.lightCardBorderOverlay),
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? (isDark
                              ? AppTheme.darkAccentText
                              : accentColor)
                          : (isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText),
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: AppConstants.animDurationMicro,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? Colors.white
                              : (isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
                          fontWeight: FontWeight.w700,
                          fontSize:   10,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
