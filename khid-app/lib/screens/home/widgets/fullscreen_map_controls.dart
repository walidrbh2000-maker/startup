// lib/screens/home/widgets/fullscreen_map_controls.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'fullscreen_filter_strip.dart';
import '../../../widgets/app_container.dart';

// ============================================================================
// FULLSCREEN MAP CONTROLS
// ============================================================================

class FullscreenMapControls extends ConsumerWidget {
  const FullscreenMapControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ─────────────────────────────────────────────────
            Row(
              children: [
                // Back button
                Semantics(
                  label:  context.tr('common.back'),
                  button: true,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(homeControllerProvider.notifier)
                        .exitMapFullscreen(),
                    child: AppCircle(
                      isDark: isDark,
                      child: Icon(
                        AppIcons.back,
                        color: isDark
                            ? AppTheme.darkText
                            : AppTheme.lightText,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // Title pill — translated filter name
                AppPill(
                  isDark: isDark,
                  child: Text(
                    homeState.activeServiceFilter != null
                        ? context.tr(
                            'services.${homeState.activeServiceFilter}')
                        : context.tr('home.explore_map'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ── Service filter strip ─────────────────────────────────────
            FullscreenFilterStrip(
              activeFilter: homeState.activeServiceFilter,
              onFilterChanged: (f) => ref
                  .read(homeControllerProvider.notifier)
                  .toggleServiceFilter(f),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

