// lib/widgets/app_section_header.dart

import 'package:flutter/material.dart';

/// A consistent uppercase section label used across About, Help,
/// Notifications, and Settings screens.
///
/// Renders [label] in `labelSmall` style, uppercased, with 1.2 letter-spacing
/// and a 4-dp directional start-padding (RTL-safe via [EdgeInsetsDirectional]).
class AppSectionHeader extends StatelessWidget {
  final String label;

  const AppSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    // Arabic has no letter case and wide tracking breaks its cursive joins —
    // skip the uppercase + positive letterSpacing when the locale is Arabic.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        isArabic ? label : label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: isArabic ? 0.0 : 1.2,
              fontWeight:    FontWeight.w700,
              color:         theme.colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
