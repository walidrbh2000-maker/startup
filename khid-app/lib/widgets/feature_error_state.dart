// lib/widgets/feature_error_state.dart

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

class FeatureErrorState extends StatelessWidget {
  final bool         isDark;
  final String       errorTitle;
  final String?      message;
  final VoidCallback onRetry;
  final String       retryLabel;
  final IconData     icon;
  final double       iconSize;

  const FeatureErrorState({
    super.key,
    required this.isDark,
    required this.errorTitle,
    required this.onRetry,
    required this.retryLabel,
    this.message,
    this.icon     = Icons.wifi_off_rounded,
    this.iconSize = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size:  iconSize,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),

            SizedBox(height: AppConstants.spacingMd),

            Text(
              errorTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            if (message != null && message!.isNotEmpty) ...[
              SizedBox(height: AppConstants.spacingSm),
              Text(
                message!,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                  fontSize: AppConstants.fontSizeMd,
                  height:   1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            SizedBox(height: AppConstants.spacingLg),

            // Solid Rose retry button (no gradient)
            Semantics(
              button: true,
              label:  retryLabel,
              child: GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLg,
                    vertical:   AppConstants.paddingMd,
                  ),
                  decoration: BoxDecoration(
                    color:        accent,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Text(
                    retryLabel,
                    style: TextStyle(
                      color:      isDark
                          ? Colors.white
                          : AppTheme.lightBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
