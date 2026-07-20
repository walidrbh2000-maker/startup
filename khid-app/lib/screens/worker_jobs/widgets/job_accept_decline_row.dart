// lib/screens/worker_jobs/widgets/job_accept_decline_row.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobAcceptDeclineRow extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const JobAcceptDeclineRow({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decline
        Expanded(
          child: Semantics(
            button: true,
            label:  context.tr('worker_jobs.decline_job'),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onDecline();
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color:        AppTheme.signOutRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(
                      color: AppTheme.signOutRed.withValues(alpha: 0.30)),
                ),
                child: Center(
                  child: Text(
                    context.tr('worker_jobs.decline_job'),
                    style: TextStyle(
                      color: Theme.of(context).brightness ==
                              Brightness.dark
                          ? AppTheme.signOutRed
                          : AppTheme.lightError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: AppConstants.spacingSm),

        // Accept — solid onlineGreen (gradient forbidden)
        Expanded(
          flex: 2,
          child: Semantics(
            button: true,
            label:  context.tr('worker_jobs.accept_job'),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onAccept();
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color:        AppTheme.onlineGreen,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('worker_jobs.accept_job'),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
