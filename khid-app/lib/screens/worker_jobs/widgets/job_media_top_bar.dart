// lib/screens/worker_jobs/widgets/job_media_top_bar.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobMediaTopBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final VoidCallback onClose;

  const JobMediaTopBar({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMd,
        MediaQuery.of(context).padding.top + 8,
        AppConstants.paddingMd,
        AppConstants.paddingMd,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: context.tr('common.close'),
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentIndex + 1} / $total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color:      Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
