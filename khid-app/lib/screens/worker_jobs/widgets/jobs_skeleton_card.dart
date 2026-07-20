// lib/screens/worker_jobs/widgets/jobs_skeleton_card.dart
// Layout only. Render inside an [AppShimmer] (see JobsSkeletonLoader).

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../widgets/app_shimmer.dart';

class JobsSkeletonCard extends StatelessWidget {
  const JobsSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.55)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const SkeletonBone(width: 48, height: 48, circle: true),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBone(width: double.infinity, height: 16),
                    SizedBox(height: 6),
                    SkeletonBone(width: 110, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              const SkeletonBone(width: 68, height: 24, radius: 100),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          const SkeletonBone(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          const SkeletonBone(width: 200, height: 12),

          const SizedBox(height: AppConstants.spacingMd),

          const Row(
            children: [
              SkeletonBone(width: 90, height: 24, radius: 100),
              SizedBox(width: 6),
              SkeletonBone(width: 66, height: 24, radius: 100),
              SizedBox(width: 6),
              SkeletonBone(width: 46, height: 24, radius: 100),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          const Row(
            children: [
              SkeletonBone(width: 36, height: 36, circle: true),
              SizedBox(width: 6),
              SkeletonBone(width: 36, height: 36, circle: true),
              Spacer(),
              SkeletonBone(width: 100, height: 36, radius: 100),
            ],
          ),
        ],
      ),
    );
  }
}
