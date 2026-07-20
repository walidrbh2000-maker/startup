// lib/screens/splash/widgets/splash_logo.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/app_theme.dart';

/// The animated K-checkmark brand mark, played once at launch.
///
/// Brand colors live in the Lottie JSON: the K glyph (bars + leg) fills with
/// the primary indigo #4F46E5; the check draws in the secondary violet
/// gradient #8B5CF6→#A78BFA — the two-tone contrast IS the mark.
///
/// Choreography (1.6s, authored in assets/animations/khidmeti_logo.json):
///   0.06–0.46s  the split left bar converges toward its gap
///   0.26–0.56s  the lower leg slides in along its own axis
///   0.46–0.93s  the checkmark draws itself through the gap — the hero beat
///   0.93–1.26s  the check lands with a 7% overshoot pop
///
/// A soft accent halo breathes in behind the mark while the check draws,
/// then stays — depth without violating the flat "Point Final" surface rule.
///
/// Under reduced motion the composition is pinned to its final frame, so the
/// logo appears fully drawn with no movement.
class SplashLogo extends StatefulWidget {
  final bool reduceMotion;
  final double size;

  const SplashLogo({
    super.key,
    required this.reduceMotion,
    this.size = 132.0,
  });

  @override
  State<SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<SplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLoaded(LottieComposition composition) {
    _controller.duration = composition.duration;
    if (widget.reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final halo = isDark ? AppTheme.darkAccentHalo : AppTheme.lightAccentHalo;

    // Halo fades in on the same clock as the check draw (0.28 → 0.70 of the
    // composition) so the glow "arrives" with the brand gesture.
    final haloOpacity = _controller.drive(
      CurveTween(curve: const Interval(0.28, 0.70, curve: Curves.easeOut)),
    );

    // Decorative — the app name is announced via the loading semantics label.
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: haloOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [halo, halo.withValues(alpha: 0.0)],
                  ),
                ),
                child: SizedBox.square(dimension: widget.size),
              ),
            ),
            Lottie.asset(
              'assets/animations/khidmeti_logo.json',
              controller: _controller,
              onLoaded: _onLoaded,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
