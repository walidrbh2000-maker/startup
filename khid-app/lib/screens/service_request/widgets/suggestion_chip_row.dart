// lib/screens/service_request/widgets/suggestion_chip_row.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SuggestionChipRow extends StatelessWidget {
  final String? serviceType;
  final bool    isDark;
  final Color   accentColor;
  final ValueChanged<String> onChipTap;

  const SuggestionChipRow({
    super.key,
    required this.serviceType,
    required this.isDark,
    required this.accentColor,
    required this.onChipTap,
  });

  static const Map<String, List<String>> _keysByType = {
    'plumber':          ['suggest_plumber_1', 'suggest_plumber_2', 'suggest_plumber_3'],
    'electrician':      ['suggest_electrician_1', 'suggest_electrician_2', 'suggest_electrician_3'],
    'cleaner':          ['suggest_cleaner_1', 'suggest_cleaner_2', 'suggest_cleaner_3'],
    'painter':          ['suggest_painter_1', 'suggest_painter_2', 'suggest_painter_3'],
    'carpenter':        ['suggest_carpenter_1', 'suggest_carpenter_2', 'suggest_carpenter_3'],
    'gardener':         ['suggest_gardener_1', 'suggest_gardener_2', 'suggest_gardener_3'],
    'ac_repair':        ['suggest_ac_repair_1', 'suggest_ac_repair_2', 'suggest_ac_repair_3'],
    'appliance_repair': ['suggest_appliance_repair_1', 'suggest_appliance_repair_2', 'suggest_appliance_repair_3'],
    'mason':            ['suggest_mason_1', 'suggest_mason_2', 'suggest_mason_3'],
  };

  static const List<String> _fallbackKeys = [
    'suggest_leak',
    'suggest_noise',
    'suggest_broken',
  ];

  @override
  Widget build(BuildContext context) {
    final keys = serviceType != null
        ? (_keysByType[serviceType] ?? _fallbackKeys)
        : _fallbackKeys;

    final chips = keys
        .map((key) => context.tr('request_form.$key'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('request_form.suggestions_label'),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.4,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
        ),
        const SizedBox(height: AppConstants.spacingXs + 2),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips
                .map(
                  (text) => Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppConstants.spacingXs + 2,
                    ),
                    child: _SuggestionChip(
                      label:      text,
                      isDark:     isDark,
                      accentColor: accentColor,
                      onTap:      () => onChipTap(text),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Single chip ───────────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool   isDark;
  final Color  accentColor;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd - 2,
            vertical:   AppConstants.spacingXs + 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusXl),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppTheme.darkAccentText : accentColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
