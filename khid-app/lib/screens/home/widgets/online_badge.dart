// lib/screens/home/widgets/online_badge.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// ONLINE BADGE
// ============================================================================

class OnlineBadge extends StatelessWidget {
  final bool isOnline;

  const OnlineBadge({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    if (!isOnline) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use onlineGreen for the dot (semantic colour), accent for container tint
    const dotColor = AppTheme.onlineGreen;
    final accent   = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical:   AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color:        accent.withValues(alpha: isDark ? 0.12 : 0.10),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.40 : 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  AppConstants.statusDotSize,
            height: AppConstants.statusDotSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            context.tr('worker_home.online'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppTheme.darkAccentText : accent,
                ),
          ),
        ],
      ),
    );
  }
}
