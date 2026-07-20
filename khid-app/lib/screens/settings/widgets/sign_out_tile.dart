// lib/screens/settings/widgets/sign_out_tile.dart
//
// The sign-out row — error-tinted like the delete row but one step softer.
// Shares colorScheme.error with _DeleteAccountTile so the two destructive
// actions keep a consistent severity weight in both themes.

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class SignOutTile extends StatelessWidget {
  final VoidCallback onSignOut;
  final bool         isEnabled;

  const SignOutTile({
    super.key,
    required this.onSignOut,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final errorColor = isEnabled
        ? theme.colorScheme.error
        : theme.colorScheme.error.withValues(
            alpha: AppConstants.opacityDisabledColor,
          );

    return Semantics(
      label:   context.tr('auth.logout'),
      button:  true,
      enabled: isEnabled,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        child: InkWell(
          onTap:        isEnabled ? onSignOut : null,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: Container(
            height: AppConstants.tileHeight,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(
                alpha: isEnabled
                    ? (isDark
                        ? AppConstants.opacityTileFillDarkEn
                        : AppConstants.opacityTileFillLightEn)
                    : AppConstants.opacityTileFillDisabled,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusTile),
              border: Border.all(
                color: theme.colorScheme.error.withValues(
                  alpha: isEnabled
                      ? AppConstants.opacityBorderEnabled
                      : AppConstants.opacityBorderDisabled,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width:  AppConstants.iconContainerXl,
                  height: AppConstants.iconContainerXl,
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: AppConstants.opacityIconBgAlt),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    AppIcons.logout,
                    color: errorColor,
                    size:  AppConstants.buttonIconSize,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingTileInner),
                Expanded(
                  child: Text(
                    context.tr('auth.logout'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: errorColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: errorColor.withValues(alpha: AppConstants.opacityChevron),
                  size:  AppConstants.buttonIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
