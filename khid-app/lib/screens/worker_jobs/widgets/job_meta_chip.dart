// lib/screens/worker_jobs/widgets/job_meta_chip.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color color;

  const JobMetaChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusXs + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppConstants.iconSizeXs, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:      isDark && color == AppTheme.darkAccent
                      ? AppTheme.darkAccentText
                      : color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
