// lib/widgets/feature_empty_state.dart

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

class FeatureEmptyState extends StatelessWidget {
  final bool     isDark;
  final IconData icon;
  final String   title;
  final String?  subtitle;
  final Widget?  action;
  final double   iconContainerSize;
  final double   iconSize;

  const FeatureEmptyState({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconContainerSize = 96.0,
    this.iconSize          = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final accent  = isDark ? AppTheme.darkAccent  : AppTheme.lightAccent;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXl,
          vertical:   AppConstants.paddingXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Solid Rose circle with glow (no gradient)
            Container(
              width:  iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: accent),
            ),

            SizedBox(height: AppConstants.spacingLg),

            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),

            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: AppConstants.spacingSm),
              Text(
                subtitle!,
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

            if (action != null) ...[
              SizedBox(height: AppConstants.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
