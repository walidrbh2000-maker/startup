// lib/screens/splash/widgets/splash_tagline.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../utils/localization.dart';

/// Per-word cascade between the two words of the entrance stagger.
const Duration _kWordStagger = Duration(milliseconds: 90);

/// The one-line brand promise beneath the wordmark, revealed word by word —
/// each word rises 6dp and fades in on its own beat, reading left→right
/// (or right→left under RTL, since Wrap lays out in text direction).
///
/// Splitting on spaces is safe for Arabic: ligature shaping happens within
/// words, never across them.
class SplashTagline extends StatelessWidget {
  final bool reduceMotion;

  /// Shifts the whole cascade so it starts as the wordmark's dot approaches.
  final Duration startDelay;

  const SplashTagline({
    super.key,
    required this.reduceMotion,
    this.startDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final words = context.tr('splash.tagline').split(' ');

    List<Widget> children = [
      for (final word in words) Text(word, style: style),
    ];

    if (!reduceMotion) {
      children = [
        for (var i = 0; i < children.length; i++)
          children[i]
              .animate()
              .fadeIn(
                delay: startDelay + _kWordStagger * i,
                duration: 320.ms,
                curve: Curves.easeOut,
              )
              .moveY(
                begin: 6,
                end: 0,
                delay: startDelay + _kWordStagger * i,
                duration: 320.ms,
                curve: Curves.easeOutCubic,
              ),
      ];
    }

    // Decorative flourish — excluded like the wordmark; the loading label
    // already announces the screen.
    return ExcludeSemantics(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4.0,
        children: children,
      ),
    );
  }
}
