// lib/screens/splash/splash_screen.dart
//
// "Point Final" — the localized wordmark closed by an accent full stop is the
// entire brand statement. Loading is a hairline sweep beneath the type; errors
// replace the hairline inside a fixed-size slot so the wordmark never moves.
//
// The native splash layer paints background color only (see
// flutter_native_splash.yaml); this screen's scaffold uses the identical
// color, so the native→Flutter handoff is imperceptible and the wordmark
// animates in from nothing.
//
// The wordmark widget is created once and never rebuilt with a new key: its
// onAnimationComplete fires exactly once per app launch, and the controller
// preserves _isAnimationComplete across retries — so no retry-count key or
// gate-reset machinery is needed here.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/splash_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/splash_logo.dart';
import 'widgets/splash_status_slot.dart';
import 'widgets/splash_tagline.dart';
import 'widgets/splash_wordmark.dart';

/// Choreography — one continuous cascade, each beat handing off to the next:
///   0.00s  logo mark starts drawing (bars converge, check draws through)
///   0.44s  wordmark rises out of its baseline mask as the check completes
///   1.15s  tagline words surface one by one beneath the name
///   1.22s  the accent dot lands (point final)
///   1.95s  the hairline loader breathes in last
const Duration _kWordmarkDelay = Duration(milliseconds: 440);
const Duration _kTaglineDelay = Duration(milliseconds: 1150);
const Duration _kStatusSlotDelay = Duration(milliseconds: 1950);

/// Logo scales with the device: ~46% of the shortest side, clamped so it
/// commands the screen on phones without swallowing small ones.
const double _kLogoMinSize = 168.0;
const double _kLogoMaxSize = 236.0;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FlutterNativeSplash.remove();
      ref.read(splashControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final state = ref.watch(splashControllerProvider);

    Widget statusSlot = SplashStatusSlot(
      state: state,
      isDark: isDark,
      reduceMotion: reduceMotion,
      onRetry: () => ref.read(splashControllerProvider.notifier).retry(),
    );
    if (!reduceMotion) {
      // Staged entrance: the slot appears only after the logo has drawn and
      // the wordmark dot has landed, keeping the mark the sole first act.
      statusSlot = statusSlot.animate().fadeIn(
            delay: _kStatusSlotDelay,
            duration: 240.ms,
            curve: Curves.easeOut,
          );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        // MUST be pixel-identical to flutter_native_splash.yaml color/color_dark.
        backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoSize = (constraints.biggest.shortestSide * 0.46)
                  .clamp(_kLogoMinSize, _kLogoMaxSize)
                  .toDouble();
              return Align(
                // Optical center — slightly above geometric center.
                alignment: const Alignment(0, -0.15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SplashLogo(reduceMotion: reduceMotion, size: logoSize),
                    const SizedBox(height: AppConstants.spacingLg),
                    SplashWordmark(
                      reduceMotion: reduceMotion,
                      startDelay: _kWordmarkDelay,
                      onAnimationComplete: () => ref
                          .read(splashControllerProvider.notifier)
                          .onAnimationComplete(),
                    ),
                    const SizedBox(height: AppConstants.spacingSmMd),
                    SplashTagline(
                      reduceMotion: reduceMotion,
                      startDelay: _kTaglineDelay,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    statusSlot,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
