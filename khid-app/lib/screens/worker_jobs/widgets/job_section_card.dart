// lib/screens/worker_jobs/widgets/job_section_card.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobSectionCard extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Color    iconColor;
  final bool     isDark;
  final Widget   child;

  const JobSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(
          color: isDark
              ? AppTheme.darkCardBorderOverlay
              : AppTheme.lightCardBorderOverlay,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  32,
                height: 32,
                decoration: BoxDecoration(
                  color:  iconColor.withValues(alpha: 0.12),
                  shape:  BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Divider(
            color: isDark
                ? AppTheme.darkTileBorder
                : AppTheme.lightTileBorder,
            height: 1,
          ),
          child,
        ],
      ),
    );
  }
}
