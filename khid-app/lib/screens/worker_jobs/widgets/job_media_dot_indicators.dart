// lib/screens/worker_jobs/widgets/job_media_dot_indicators.dart

import 'package:flutter/material.dart';

class JobMediaDotIndicators extends StatelessWidget {
  final int count;
  final int current;

  const JobMediaDotIndicators({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == current
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

