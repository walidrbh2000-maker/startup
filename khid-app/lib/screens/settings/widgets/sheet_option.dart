// lib/screens/settings/widgets/sheet_option.dart
//
// One selectable row inside the language / theme bottom sheet: a flag or icon,
// a label, and a check when selected. Accent-tinted fill + border when active.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class SheetOption extends StatelessWidget {
  final String     label;
  final String?    flag;
  final IconData?  icon;
  final bool       isSelected;
  final VoidCallback onTap;

  const SheetOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.flag,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final borderRadius = BorderRadius.circular(AppConstants.radiusLg);

    return Semantics(
      label:    label,
      selected: isSelected,
      button:   true,
      child: AnimatedContainer(
        duration:  AppConstants.animDurationMicro,
        margin:    const EdgeInsets.only(bottom: AppConstants.spacingSm),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(
                  alpha: isDark
                      ? AppConstants.opacitySheetFillDark
                      : AppConstants.opacitySheetFillLight,
                )
              : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: AppConstants.opacitySheetBorderSel)
                : theme.colorScheme.outline.withValues(
                    alpha: AppConstants.opacitySheetBorderUnsel,
                  ),
            width: isSelected
                ? AppConstants.borderWidthSelected
                : AppConstants.borderWidthDefault,
          ),
        ),
        child: Material(
          color:        Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap:        onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMd,
                vertical: AppConstants.spacingTileInner,
              ),
              child: Row(
                children: [
                  if (flag != null)
                    Text(flag!, style: TextStyle(fontSize: AppConstants.emojiIconSize))
                  else if (icon != null)
                    Icon(
                      icon,
                      size: AppConstants.emojiIconSize,
                      color: isSelected
                          ? accent
                          : theme.colorScheme.onSurface.withValues(
                              alpha: AppConstants.opacitySheetIconMuted,
                            ),
                    ),
                  const SizedBox(width: AppConstants.spacingTileInner),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? (isDark ? AppTheme.darkAccentText : accent)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: accent, size: AppConstants.buttonIconSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
