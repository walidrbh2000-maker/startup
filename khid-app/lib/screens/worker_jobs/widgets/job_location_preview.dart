// lib/screens/worker_jobs/widgets/job_location_preview.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../utils/app_config.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class JobLocationPreview extends StatelessWidget {
  final ServiceRequestEnhancedModel job;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onOpen;

  const JobLocationPreview({
    super.key,
    required this.job,
    required this.isDark,
    required this.accentColor,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: Column(
        children: [
          // Map preview
          GestureDetector(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: SizedBox(
                height: 150,
                child: AbsorbPointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                          job.userLatitude, job.userLongitude),
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark
                            ? 'https://api.maptiler.com/maps/streets-v2-dark/256/{z}/{x}/{y}{r}.png?key=${AppConfig.maptilerApiKey}'
                            : 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}{r}.png?key=${AppConfig.maptilerApiKey}',
                        userAgentPackageName: 'com.khidmeti.app',
                        retinaMode:
                            MediaQuery.of(context).devicePixelRatio > 1.0,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(job.userLatitude,
                                job.userLongitude),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                // Neutral depth shadow, not an accent glow.
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              // White on accent = 6.4:1, passes AA.
                              child: const Icon(
                                Icons.person_pin_circle_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          // Address + open button
          Row(
            children: [
              Icon(AppIcons.location,
                  size: 14,
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  job.userAddress.isNotEmpty
                      ? job.userAddress
                      : context.tr('worker_jobs.client_location'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: context.tr('worker_jobs.open_full_map'),
                child: GestureDetector(
                  onTap: onOpen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSm),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen_rounded,
                            size: 13,
                            color: isDark
                                ? AppTheme.darkAccentText
                                : accentColor),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('worker_jobs.open_full_map'),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: isDark
                                    ? AppTheme.darkAccentText
                                    : accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
