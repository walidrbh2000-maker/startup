// lib/widgets/app_sliver_header.dart
//
// Shared scrolling header for content screens (about, help, notifications).
// One header for all: same background token, no surface tint / scroll
// elevation, left-aligned title closed by the Point Final accent full stop,
// and the shared AppBarBackButton leading (Semantics + tooltip a11y contract).

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'back_button.dart';
import 'wordmark.dart';

class AppSliverHeader extends StatelessWidget {
  /// Localised title text, e.g. `context.tr('profile.about')`.
  final String title;

  /// Leading (back) tap handler. When null, defaults to [appBack]
  /// (pop when there is history, otherwise land on home).
  final VoidCallback? onBack;

  const AppSliverHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    // Pinned (not .medium): keeps the title on the same row as the back
    // button instead of the expanded large-title row below it.
    return SliverAppBar(
      pinned:                 true,
      backgroundColor:        bgColor,
      surfaceTintColor:       Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle:            false,
      title:                  PointFinalTitle(title),
      leading:                AppBarBackButton(onPressed: onBack),
    );
  }
}
