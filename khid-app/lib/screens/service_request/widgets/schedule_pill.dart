// lib/screens/service_request/widgets/schedule_pill.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ============================================================================
// SCHEDULE PILL
// Full-width, equal-column pill for ASAP / Ce soir / Planifier.
// Active state: filled with accent.  Inactive: surface + muted text.
// ============================================================================

class SchedulePill extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool isActive;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const SchedulePill({
    super.key,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.isActive,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label — $subLabel',
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingXs,
            vertical:   AppConstants.spacingTileInner,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor
                : (isDark
                    ? AppTheme.darkSurface
                    : AppTheme.lightSurface),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isActive
                  ? accentColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: AppConstants.fontSizeXxs,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      // subLabel uses fontSizeXxs (11dp) — meets platform minimum
                      fontSize: AppConstants.fontSizeXxs,
                      fontWeight: FontWeight.w400,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.70)
                          : (isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
