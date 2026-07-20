// lib/screens/home/widgets/home_map_background.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers/home_controller.dart';
import '../../../utils/app_config.dart';
import '../../../utils/constants.dart';
import 'pulsing_location_dot.dart';
import 'worker_map_marker.dart';

// ============================================================================
// HOME MAP BACKGROUND
// ============================================================================

class HomeMapBackground extends ConsumerStatefulWidget {
  const HomeMapBackground({super.key});

  @override
  ConsumerState<HomeMapBackground> createState() => _HomeMapBackgroundState();
}

class _HomeMapBackgroundState extends ConsumerState<HomeMapBackground> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark          = Theme.of(context).brightness == Brightness.dark;
    // select() stored fields only — watching the whole HomeState rebuilt the
    // entire map (tiles + markers) on every address resolve / isRefreshing
    // toggle. filteredWorkers is a computed getter (fresh list per read, so
    // select can't dedupe it) — derive it locally from its stable inputs.
    final isFullscreen =
        ref.watch(homeControllerProvider.select((s) => s.isMapFullscreen));
    final userLocation =
        ref.watch(homeControllerProvider.select((s) => s.userLocation));
    final nearbyWorkers =
        ref.watch(homeControllerProvider.select((s) => s.nearbyWorkers));
    final activeFilter = ref
        .watch(homeControllerProvider.select((s) => s.activeServiceFilter));
    final bestWorkerId =
        ref.watch(homeControllerProvider.select((s) => s.bestWorkerId));
    final filteredWorkers = activeFilter == null
        ? nearbyWorkers
        : nearbyWorkers.where((w) => w.profession == activeFilter).toList();

    // Fly to user location once it resolves
    ref.listen<LatLng?>(
      homeControllerProvider.select((s) => s.userLocation),
      (prev, next) {
        if (next != null && next != prev) {
          _mapController.move(next, AppConstants.defaultZoom + 1);
        }
      },
    );

    // MapTiler tiles — professional quality, no API key in source code.
    // Key is read at runtime from Firebase Remote Config via AppConfig.
    // dark  → Streets v2 Dark (blue-navy, Indigo-compatible)
    // light → Streets v2 (clean white, sharp labels)
    final mapKey  = AppConfig.maptilerApiKey;
    final tileUrl = isDark
        ? 'https://api.maptiler.com/maps/streets-v2-dark/256/{z}/{x}/{y}{r}.png?key=$mapKey'
        : 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}{r}.png?key=$mapKey';

    // Fix: filter workers that have valid coordinates before building markers.
    // Previously w.latitude! / w.longitude! would crash on null values.
    final validWorkers = filteredWorkers
        .where((w) => w.latitude != null && w.longitude != null)
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userLocation ?? AppConstants.cityCenters['alger']!,
        initialZoom:   AppConstants.defaultZoom,
        minZoom:       AppConstants.minZoom,
        maxZoom:       AppConstants.maxZoom,
        interactionOptions: InteractionOptions(
          flags: isFullscreen
              ? InteractiveFlag.all
              : InteractiveFlag.none,
        ),
      ),
      children: [
        // Tile layer
        TileLayer(
          urlTemplate:          tileUrl,
          userAgentPackageName: 'com.khidmeti',
          maxZoom:              20,
          retinaMode:
              MediaQuery.of(context).devicePixelRatio > 1.0,
        ),

        // User location marker — locationDotMarker(38dp) leaves room for the
        // ripple ring (locationDotSize 16dp scaled to 2.2x) without clipping.
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point:  userLocation,
                width:  AppConstants.locationDotMarker,
                height: AppConstants.locationDotMarker,
                child:  const PulsingLocationDot(),
              ),
            ],
          ),

        // Worker markers (fullscreen only). Box sizes give the 56/48dp bubbles
        // + pointer + best-badge overflow a few dp of clearance — see
        // worker_map_marker.dart before changing.
        if (isFullscreen && validWorkers.isNotEmpty)
          MarkerLayer(
            markers: validWorkers
                .map(
                  (w) => Marker(
                    point:  LatLng(w.latitude!, w.longitude!),
                    width:  w.id == bestWorkerId ? 64 : 52,
                    height: w.id == bestWorkerId ? 72 : 60,
                    child:  WorkerMapMarker(
                      worker:   w,
                      isBest:   w.id == bestWorkerId,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
