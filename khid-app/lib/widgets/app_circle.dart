// lib/widgets/app_circle.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ============================================================================
// CIRCLE  (map overlay — 48×48 circular button)
// Used by FullscreenMapControls for the back button.
// Exempt from flat-surface rule — map overlays require blur for legibility.
//
// FIX (Structure): Extracted from app_container.dart.
// Original file contained AppCircle + AppPill + AppIconButton in one
// file — violation of the one-class-per-file rule.
// ============================================================================

class AppCircle extends StatelessWidget {
  final Widget child;
  final bool   isDark;

  const AppCircle({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width:  48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.black.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
