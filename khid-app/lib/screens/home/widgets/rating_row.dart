// lib/screens/home/widgets/rating_row.dart

import 'package:flutter/material.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ============================================================================
// RATING ROW
// ============================================================================

class RatingRow extends StatelessWidget {
  final WorkerModel worker;
  const RatingRow({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final starColor  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Row(
      children: [
        Icon(AppIcons.ratingFilled, color: starColor, size: AppConstants.iconSizeXs),
        const SizedBox(width: AppConstants.spacingXxs),
        Text(
          worker.averageRating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          ' (${worker.ratingCount})',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
