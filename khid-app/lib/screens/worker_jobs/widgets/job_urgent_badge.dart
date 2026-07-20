// lib/screens/worker_jobs/widgets/job_urgent_badge.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobUrgentBadge extends StatefulWidget {
  final bool isDark;

  const JobUrgentBadge({super.key, required this.isDark});

  @override
  State<JobUrgentBadge> createState() => _JobUrgentBadgeState();
}

class _JobUrgentBadgeState extends State<JobUrgentBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Opacity(
          opacity: _anim.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.signOutRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusXs + 2),
              border: Border.all(
                  color: AppTheme.signOutRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on_rounded,
                    size: AppConstants.iconSizeXs, color: AppTheme.signOutRed),
                const SizedBox(width: 4),
                Text(
                  context.tr('worker_jobs.urgent_priority'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.signOutRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
