// lib/widgets/app_icon_button.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

// ============================================================================
// ICON BUTTON  (map overlay — 48×48 icon button)
// Used by HomeTopBar for the notification button.
// Exempt from flat-surface rule — map overlays require blur for legibility.
//
// FIX (Structure): Extracted from app_container.dart.
// ============================================================================

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final bool     isDark;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width:  48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.09)
                : Colors.white.withValues(alpha: 0.72),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.90),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isDark
                ? AppTheme.darkAccentText
                : Theme.of(context).colorScheme.primary,
            size:  22,
          ),
        ),
      ),
    );
  }
}
