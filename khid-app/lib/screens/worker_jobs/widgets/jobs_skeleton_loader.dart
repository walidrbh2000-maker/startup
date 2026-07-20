// lib/screens/worker_jobs/widgets/jobs_skeleton_loader.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../widgets/app_shimmer.dart';
import 'jobs_skeleton_card.dart';

class JobsSkeletonLoader extends StatelessWidget {
  const JobsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingMd),
        child: Column(
          children: List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(
                bottom: i < 3 ? AppConstants.spacingMd : 0,
              ),
              child: const JobsSkeletonCard(),
            ),
          ),
        ),
      ),
    );
  }
}
