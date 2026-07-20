// lib/screens/splash/widgets/splash_wordmark.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../utils/localization.dart';

/// The localized app name closed by an accent-colored full stop — the single
/// brand gesture of the splash ("point final").
///
/// Entrance: the word rises out of a clip mask sized to its own text box
/// (masked baseline reveal — it appears to surface from the page itself)
/// while the logo's check draws; the dot then lands with an overshoot pop,
/// the last brand motion on screen.
///
/// The dot is a trailing Row child, so under RTL it renders at the visual end
/// of «خدمتي» automatically — no locale branching needed for position.
class SplashWordmark extends StatelessWidget {
  final bool reduceMotion;

  /// Fires once when the dot has landed — the last brand motion on screen.
  /// Idempotent on the controller side, so stray re-fires are harmless.
  final VoidCallback onAnimationComplete;

  /// Shifts the whole entrance so the type can wait for the logo mark's
  /// check-draw beat (see SplashLogo) before rising.
  final Duration startDelay;

  const SplashWordmark({
    super.key,
    required this.reduceMotion,
    required this.onAnimationComplete,
    this.startDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Negative tracking breaks Arabic ligature shaping — gate on locale,
    // not Directionality (an RTL layout can still render Latin text).
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final wordStyle =
        (theme.textTheme.displayLarge ?? const TextStyle()).copyWith(
      letterSpacing: isArabic ? 0.0 : null,
    );

    Widget word = Text(context.tr('common.app_name'), style: wordStyle);
    Widget dot = Text(
      '.',
      style: wordStyle.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 0,
      ),
    );

    if (reduceMotion) {
      // Entrance skipped — open the gate on the next frame.
      SchedulerBinding.instance
          .addPostFrameCallback((_) => onAnimationComplete());
    } else {
      // Masked baseline reveal: the translate happens at paint time, so the
      // ClipRect keeps the static text-box bounds and crops the word until
      // it has fully risen. No reflow, no fade-only primitive.
      word = ClipRect(
        child: word
            .animate()
            .moveY(
              begin: 44,
              end: 0,
              delay: startDelay,
              duration: 560.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(
              delay: startDelay,
              duration: 400.ms,
              curve: Curves.easeOut,
            ),
      );
      // The dot lands with a slight overshoot as the word settles, anchored
      // to its bottom edge so the baseline never shifts.
      dot = dot
          .animate(onComplete: (_) => onAnimationComplete())
          .fadeIn(
            delay: startDelay + 480.ms,
            duration: 120.ms,
            curve: Curves.easeOut,
          )
          .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1.0, 1.0),
            delay: startDelay + 480.ms,
            duration: 300.ms,
            curve: Curves.easeOutBack,
            alignment: Alignment.bottomCenter,
          );
    }

    // Decorative — the app name is announced via the loading semantics label.
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [word, dot],
      ),
    );
  }
}
