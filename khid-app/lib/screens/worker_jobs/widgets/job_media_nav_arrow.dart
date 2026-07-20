// lib/screens/worker_jobs/widgets/job_media_nav_arrow.dart

import 'package:flutter/material.dart';

class JobMediaNavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const JobMediaNavArrow({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

