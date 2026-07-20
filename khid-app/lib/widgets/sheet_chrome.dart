// lib/widgets/sheet_chrome.dart
//
// Shared bottom-sheet chrome widgets:
//   • SheetHandle  — the drag indicator bar at the top of every sheet
//   • SheetCloseButton — 48×48 tap zone / 32dp visual circle close button
//
// Extracted from 5+ sheets (ai_search_sheet, image_search_sheet,
// voice_search_sheet, worker_preview_sheet, worker_story_modal,
// home_categories_sheet) where the pattern was duplicated verbatim.

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

// ============================================================================
// SHEET HANDLE
// ============================================================================

/// The standard drag-indicator pill at the top of bottom sheets.
///
/// Usage:
/// ```dart
/// const SheetHandle()          // reads isDark from Theme automatically
/// SheetHandle(isDark: isDark)  // explicit override
/// ```
class SheetHandle extends StatelessWidget {
  /// When `null` (default) the widget reads [Brightness] from the ambient
  /// [Theme]. Pass an explicit value to override.
  final bool? isDark;

  const SheetHandle({super.key, this.isDark});

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width:  AppConstants.sheetHandleWidth,
        height: AppConstants.sheetHandleHeight,
        decoration: BoxDecoration(
          color:        dark ? AppTheme.darkBorder : AppTheme.lightBorder,
          borderRadius: BorderRadius.circular(AppConstants.radiusXs),
        ),
      ),
    );
  }
}

// ============================================================================
// SHEET CLOSE BUTTON
// ============================================================================

/// A circular close button with a 48×48 accessible tap zone and a 32dp
/// visual container. Reads the current theme automatically.
///
/// Usage:
/// ```dart
/// SheetCloseButton(onTap: () => Navigator.pop(context))
/// ```
///
/// With custom semantics label (for localisation):
/// ```dart
/// SheetCloseButton(
///   onTap:           () => Navigator.pop(context),
///   semanticsLabel:  context.tr('common.close'),
/// )
/// ```
class SheetCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  final String?      semanticsLabel;

  const SheetCloseButton({
    super.key,
    required this.onTap,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label:  semanticsLabel ?? 'Close',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width:  AppConstants.buttonHeightMd,  // 48dp tap zone
          height: AppConstants.buttonHeightMd,
          child: Center(
            child: Container(
              width:  AppConstants.iconContainerMd,  // 32dp visual
              height: AppConstants.iconContainerMd,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppTheme.darkSurface
                    : AppTheme.lightSurfaceVariant,
              ),
              child: Center(
                child: Icon(
                  AppIcons.close,
                  size:  AppConstants.iconSizeXs,  // 16dp
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
