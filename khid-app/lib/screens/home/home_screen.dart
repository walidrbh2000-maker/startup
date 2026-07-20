// lib/screens/home/home_screen.dart
//
// Layered stack: map (always built) under a solid cover + accent glow that
// fade away when the map goes fullscreen. SafeArea(bottom: false) so the
// background runs edge-to-edge behind the floating nav bar; bottom clearance
// is added manually at the end of the scroll column
// (navBarScrollClearance + device bottom inset).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/home_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/advanced_search_bar.dart';
import 'widgets/fullscreen_map_controls.dart';
import 'widgets/home_map_background.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_skeleton_loading.dart';
import 'widgets/home_top_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _transitionCtrl;
  late Animation<double>   _uiFade;
  late Animation<double>   _mapBlur;

  @override
  void initState() {
    super.initState();
    _transitionCtrl = AnimationController(
      vsync:    this,
      duration: AppConstants.animDurationShort,
    );
    _uiFade = CurvedAnimation(
      parent:       _transitionCtrl,
      curve:        Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _mapBlur = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // .select scopes: rebuild only when the skeleton gate or fullscreen flips.
    final showSkeleton = ref.watch(homeControllerProvider.select(
      (s) => s.userLocation == null &&
             s.locationStatus == HomeLocationStatus.loading,
    ));

    if (showSkeleton) {
      return const HomeSkeletonLoading();
    }

    final isFullscreen = ref.watch(
      homeControllerProvider.select((s) => s.isMapFullscreen),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    final double bottomClearance =
        AppConstants.navBarScrollClearance +
        MediaQuery.viewPaddingOf(context).bottom;

    ref.listen<bool>(
      homeControllerProvider.select((s) => s.isMapFullscreen),
      (_, next) {
        if (next) {
          _transitionCtrl.forward();
          SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle(true));
        } else {
          _transitionCtrl.reverse();
          SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle(isDark));
        }
      },
    );

    return PopScope(
      canPop: !isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isFullscreen) {
          ref.read(homeControllerProvider.notifier).exitMapFullscreen();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ── LAYER 0 ─────────────────────────────────────────────────────
            // Map always built under the cover, ready for fullscreen instantly.
            const Positioned.fill(child: HomeMapBackground()),

            // ── LAYER 1 ─────────────────────────────────────────────────────
            // Solid cover: hides the map in normal mode, fades on fullscreen.
            AnimatedBuilder(
              animation: _mapBlur,
              builder: (_, __) {
                final coverOpacity = (1.0 - _mapBlur.value).clamp(0.0, 1.0);
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: (isDark
                              ? AppTheme.darkBackground
                              : AppTheme.lightBackground)
                          .withValues(alpha: coverOpacity),
                    ),
                  ),
                );
              },
            ),

            // ── LAYER 1.5 ────────────────────────────────────────────────────
            // RadialGlow: accent halo centred in the upper third.
            AnimatedBuilder(
              animation: _mapBlur,
              builder: (_, __) {
                final glowOpacity = (1.0 - _mapBlur.value).clamp(0.0, 1.0);
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.85),
                          radius: 0.9,
                          colors: [
                            accent.withValues(
                              alpha: (isDark ? 0.35 : 0.22) * glowOpacity,
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── LAYER 2 ──────────────────────────────────────────────────────
            // Normal scrollable UI: fades out on fullscreen entry.
            AnimatedBuilder(
              animation: _uiFade,
              builder: (_, child) => IgnorePointer(
                ignoring: isFullscreen,
                child: Opacity(
                  opacity: (1.0 - _uiFade.value).clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeTopBar(),
                      const AdvancedSearchBar(),
                      const HomeQuickActions(),

                      // Scroll clearance — keeps last card fully above nav bar.
                      // = navBarScrollClearance(96dp) + device bottom inset.
                      SizedBox(height: bottomClearance),
                    ],
                  ),
                ),
              ),
            ),

            // ── LAYER 3 ──────────────────────────────────────────────────────
            // Fullscreen map controls: visible only in fullscreen mode.
            AnimatedBuilder(
              animation: _uiFade,
              builder: (_, child) => IgnorePointer(
                ignoring: !isFullscreen,
                child: Opacity(
                  opacity: _uiFade.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: const Align(
                alignment: Alignment.topLeft,
                child: FullscreenMapControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
