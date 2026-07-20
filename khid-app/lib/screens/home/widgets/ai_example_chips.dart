// lib/screens/home/widgets/ai_example_chips.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class AiExampleChips extends StatelessWidget {
  final bool                 isDark;
  final ValueChanged<String> onTap;

  const AiExampleChips({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  // Intentionally NOT localized — these are multilingual typed examples that
  // demonstrate code-switching (Darija + French + Arabic). They are input
  // demos, not UI labels, so they must stay as-is regardless of app locale.
  static const List<String> _examples = [
    'ماء ساقط من السقف',
    'الضوء مقطوع',
    "fuite d'eau",
    'الفريج ما يبردش',
    'باب ما يقفلش',
    'صنفارية مسدودة',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.buttonHeightMd,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLg),
        itemCount:        _examples.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppConstants.spacingXs),
        itemBuilder: (context, i) {
          final label = _examples[i];
          return Semantics(
            label:  label,
            button: true,
            child: GestureDetector(
              onTap: () => onTap(label),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSm,
                    vertical:   AppConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCircle),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
