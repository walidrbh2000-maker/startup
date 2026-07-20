// lib/screens/worker_jobs/widgets/job_pill_badge.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class JobPillBadge extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final Color color;

  const JobPillBadge({
    super.key,
    required this.icon,
    this.iconSize = 14,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

