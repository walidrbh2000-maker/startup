// lib/screens/worker_jobs/widgets/job_detail_hero_background.dart

import 'package:flutter/material.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobDetailHeroBackground extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool  isDark;
  final Color accentColor;

  const JobDetailHeroBackground({
    super.key,
    required this.job,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final serviceColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      // Flat surface — the ghost profession icon is the only hero gesture
      // (same family as the onboarding ghost numerals).
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: Stack(
        children: [
          // Background service icon (watermark)
          Positioned(
            right: -20,
            top:   -10,
            child: Opacity(
              opacity: isDark ? 0.07 : 0.05,
              child: Icon(
                AppTheme.getProfessionIcon(job.serviceType),
                size:  180,
                color: serviceColor,
              ),
            ),
          ),

          // ID badge
          Positioned(
            top:   16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${job.id.substring(0, job.id.length.clamp(0, 8)).toUpperCase()}',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize:   AppConstants.fontSizeXxs,
                    fontFamily: AppConstants.monoFontFamily,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
