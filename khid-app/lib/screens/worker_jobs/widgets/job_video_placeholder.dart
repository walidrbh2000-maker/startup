// lib/screens/worker_jobs/widgets/job_video_placeholder.dart

import 'package:flutter/material.dart';

import '../../../utils/localization.dart';

class JobVideoPlaceholder extends StatelessWidget {
  final String url;
  final bool   isDark;

  const JobVideoPlaceholder({
    super.key,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width:  80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white70,
              size:  44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('worker_jobs.video_preview_unavailable'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                ),
          ),
        ],
      ),
    );
  }
}
