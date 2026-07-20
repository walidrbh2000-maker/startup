// lib/screens/settings/widgets/settings_tile.dart
//
// A single settings row: surface card, tinted icon chip, title + optional
// subtitle, and a trailing chevron (or a caller-supplied trailing widget).

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class SettingsTile extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       title;
  final String?      subtitle;
  final VoidCallback onTap;
  final String       semanticsLabel;
  final Widget?      trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.semanticsLabel,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:  semanticsLabel,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spacingXxs),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: InkWell(
            onTap:        onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusTile),
            child: Container(
              height: AppConstants.tileHeight,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusTile),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: AppConstants.cardBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:  AppConstants.iconContainerXl,
                    height: AppConstants.iconContainerXl,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(
                        alpha: AppConstants.opacityIconBgAlt,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size:  AppConstants.buttonIconSize,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingTileInner),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppConstants.spacingXxs),
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size:  AppConstants.buttonIconSize,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
