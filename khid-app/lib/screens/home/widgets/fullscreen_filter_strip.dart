// lib/screens/home/widgets/fullscreen_filter_strip.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// FULLSCREEN FILTER STRIP
// ============================================================================

class FullscreenFilterStrip extends StatefulWidget {
  final String?               activeFilter;
  final ValueChanged<String?> onFilterChanged;
  final bool                  isDark;

  const FullscreenFilterStrip({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.isDark,
  });

  @override
  State<FullscreenFilterStrip> createState() => _FullscreenFilterStripState();
}

class _FullscreenFilterStripState extends State<FullscreenFilterStrip> {
  late List<(String?, String, IconData)> _chips;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chips = [
      (null,                        context.tr('home.filter_all'),           Icons.apps_rounded),
      (ServiceType.plumbing,        context.tr('services.plumbing'),         AppIcons.plumbing),
      (ServiceType.electrical,      context.tr('services.electrical'),       AppIcons.electrical),
      (ServiceType.cleaning,        context.tr('services.cleaning'),         AppIcons.cleaning),
      (ServiceType.painting,        context.tr('services.painting'),         AppIcons.painting),
      (ServiceType.carpentry,       context.tr('services.carpentry'),        AppIcons.carpentry),
      (ServiceType.gardening,       context.tr('services.gardening'),        AppIcons.gardening),
      (ServiceType.airConditioning, context.tr('services.air_conditioning'), AppIcons.airConditioning),
      (ServiceType.appliances,      context.tr('services.appliances'),       AppIcons.appliances),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final chips  = _chips;

    return SizedBox(
      height: AppConstants.buttonHeightMd, // 48dp
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics:         const BouncingScrollPhysics(),
        itemCount:       chips.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppConstants.spacingChipGap),
        itemBuilder: (context, i) {
          final (type, label, icon) = chips[i];
          final isActive = widget.activeFilter == type;

          return Semantics(
            label:    label,
            selected: isActive,
            button:   true,
            child: GestureDetector(
              onTap: () => widget.onFilterChanged(type),
              child: AnimatedContainer(
                duration: AppConstants.animDurationMicro,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSm,
                  vertical:   AppConstants.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? accent.withValues(alpha: 0.28)
                      : (widget.isDark
                          ? AppTheme.darkSurface.withValues(alpha: 0.85)
                          : AppTheme.lightSurface.withValues(alpha: 0.82)),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isActive ? accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size:  14,
                      color: isActive
                          ? (widget.isDark ? AppTheme.darkAccentText : accent)
                          : (widget.isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText),
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isActive
                                ? (widget.isDark
                                    ? AppTheme.darkAccentText
                                    : accent)
                                : (widget.isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText),
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
