// lib/widgets/wordmark.dart
//
// The "point final" brand gestures introduced on the splash screen:
//   [AppWordmark] — the localized app name closed by an accent full stop.
//   [AccentRule]  — the short accent hairline used above headings.

import 'package:flutter/material.dart';

import '../utils/localization.dart';

class AppWordmark extends StatelessWidget {
  /// Text style for the name. Defaults to titleMedium w700 — top-bar size.
  final TextStyle? style;

  const AppWordmark({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Negative tracking breaks Arabic ligature shaping — gate on locale.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final wordStyle = (style ??
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
        ?.copyWith(letterSpacing: isArabic ? 0.0 : -0.2);

    // Decorative — screens announce the app name via their own semantics.
    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          text: context.tr('common.app_name'),
          style: wordStyle,
          children: [
            TextSpan(
              text: '.',
              style: wordStyle?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen title closed by the accent full stop — for AppBar titles and
/// header rows where the title sits beside the back button.
class PointFinalTitle extends StatelessWidget {
  final String title;

  const PointFinalTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    // Negative tracking breaks Arabic ligature shaping — gate on locale.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final style    = theme.textTheme.titleLarge?.copyWith(
      fontWeight:    FontWeight.w700,
      letterSpacing: isArabic ? 0.0 : -0.3,
    );

    return Text.rich(
      TextSpan(
        text: title,
        style: style,
        children: [
          TextSpan(
            text: '.',
            style: style?.copyWith(
              color:         theme.colorScheme.primary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Short accent hairline — the rule motif from the splash loader.
class AccentRule extends StatelessWidget {
  static const double _width  = 40.0;
  static const double _height = 2.0;

  const AccentRule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
    );
  }
}
