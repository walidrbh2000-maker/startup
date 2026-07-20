// lib/screens/worker_jobs/widgets/job_location_map_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/app_config.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_chrome.dart';

class JobLocationMapSheet extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;
  final String clientName;

  const JobLocationMapSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.clientName,
  });

  static Future<void> show(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String address,
    required String clientName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => JobLocationMapSheet(
        latitude: latitude,
        longitude: longitude,
        address: address,
        clientName: clientName,
      ),
    );
  }

  @override
  State<JobLocationMapSheet> createState() => _JobLocationMapSheetState();
}

class _JobLocationMapSheetState extends State<JobLocationMapSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final clientLocation = LatLng(widget.latitude, widget.longitude);

    return SizedBox(
      height: sheetHeight + bottomPad,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl)),
        child: Column(
          children: [
            // Handle + Header — opaque surface; a backdrop blur behind a
            // ~96%-alpha fill was invisible cost.
            Container(
              padding: EdgeInsets.fromLTRB(
                AppConstants.paddingLg,
                AppConstants.paddingMd,
                AppConstants.paddingLg,
                AppConstants.paddingMd,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Column(
                    children: [
                      SheetHandle(isDark: isDark),
                      const SizedBox(height: AppConstants.spacingMd),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(AppIcons.location,
                                color: accentColor, size: 20),
                          ),
                          const SizedBox(width: AppConstants.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.clientName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.address.isNotEmpty
                                      ? widget.address
                                      : context
                                          .tr('worker_jobs.client_location'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? AppTheme.darkSecondaryText
                                            : AppTheme.lightSecondaryText,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          // Open in Maps button
                          Semantics(
                            button: true,
                            label: context.tr('worker_jobs.open_in_maps'),
                            child: GestureDetector(
                              onTap: _openInMaps,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusMd),
                                  border: Border.all(
                                      color: accentColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions_rounded,
                                        size: 15,
                                        color: isDark
                                            ? AppTheme.darkAccentText
                                            : accentColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      context.tr('worker_jobs.open_in_maps'),
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
            ),

            // Map
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: clientLocation,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://api.maptiler.com/maps/streets-v2-dark/256/{z}/{x}/{y}{r}.png?key=${AppConfig.maptilerApiKey}'
                        : 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}{r}.png?key=${AppConfig.maptilerApiKey}',
                    userAgentPackageName: 'com.khidmeti',
                    retinaMode:
                        MediaQuery.of(context).devicePixelRatio > 1.0,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: clientLocation,
                        width: 72,
                        height: 72,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, _) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulse ring
                                Container(
                                  width: 64 * _pulseAnim.value,
                                  height: 64 * _pulseAnim.value,
                                  decoration: BoxDecoration(
                                    color: accentColor
                                        .withValues(alpha: 0.15 * (1 - _pulseAnim.value + 0.3)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentColor
                                          .withValues(alpha: 0.3 * (1 - _pulseAnim.value + 0.3)),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Core marker
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    // Neutral depth shadow, not an accent glow.
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
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
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Coordinate badge
            Container(
              padding: EdgeInsets.fromLTRB(
                AppConstants.paddingMd,
                AppConstants.spacingSm,
                AppConstants.paddingMd,
                AppConstants.spacingSm + bottomPad,
              ),
              color: isDark
                  ? AppTheme.darkSurface
                  : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gps_fixed_rounded,
                    size: 13,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFamily: AppConstants.monoFontFamily,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
