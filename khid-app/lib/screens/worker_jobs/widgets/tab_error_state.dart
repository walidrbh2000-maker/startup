// lib/screens/worker_jobs/widgets/tab_error_state.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// TAB ERROR STATE
// Extracted from _TabErrorState in worker_jobs_screen.dart.
// Shows a user-safe error message and an optional retry button.
// Raw controller error strings are never forwarded to the user.
// ============================================================================

class TabErrorState extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onRetry;

  const TabErrorState({
    super.key,
    required this.isDark,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXl,
          vertical: AppConstants.spacingXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: secondaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              context.tr('errors.generic'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: errorColor),
                child: Text(
                  context.tr('common.retry'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
