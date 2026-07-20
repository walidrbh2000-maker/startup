// lib/screens/service_request/widgets/location_map_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../utils/app_config.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// Algiers — fallback when no GPS fix is available yet
const _kDefaultLat = 36.7372;
const _kDefaultLng = 3.0863;
const _kMapH       = 190.0;

class LocationMapPicker extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String  address;
  final bool    isDark;
  final Color   accentColor;
  final bool    isLocating;
  final bool    isGeocoding;
  final void Function(double lat, double lng) onLocationChanged;

  const LocationMapPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isDark,
    required this.accentColor,
    required this.isLocating,
    required this.isGeocoding,
    required this.onLocationChanged,
  });

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  final _mapController = MapController();
  bool  _isDragging    = false;
  bool  _mapReady      = false;

  LatLng get _center => LatLng(
        widget.latitude  ?? _kDefaultLat,
        widget.longitude ?? _kDefaultLng,
      );

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LocationMapPicker old) {
    super.didUpdateWidget(old);
    if (_mapReady &&
        !_isDragging &&
        widget.latitude  != null &&
        widget.longitude != null &&
        (widget.latitude  != old.latitude ||
         widget.longitude != old.longitude)) {
      _mapController.move(
        LatLng(widget.latitude!, widget.longitude!),
        15.0,
      );
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      if (!_isDragging) setState(() => _isDragging = true);
    } else if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd) {
      setState(() => _isDragging = false);
      final c = _mapController.camera.center;
      widget.onLocationChanged(c.latitude, c.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Map canvas ──────────────────────────────────────────────
        SizedBox(
          height: _kMapH,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLg),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom:   15.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady:  () => setState(() => _mapReady = true),
                    onMapEvent:  _onMapEvent,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: widget.isDark
                          ? 'https://api.maptiler.com/maps/streets-v2-dark/256/{z}/{x}/{y}{r}.png?key=${AppConfig.maptilerApiKey}'
                          : 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}{r}.png?key=${AppConfig.maptilerApiKey}',
                      userAgentPackageName: 'com.khidmeti.app',
                      retinaMode:
                          MediaQuery.of(context).devicePixelRatio > 1.0,
                    ),
                  ],
                ),

                IgnorePointer(
                  child: _CrosshairPin(
                    isDragging:  _isDragging,
                    isLocating:  widget.isLocating,
                    accentColor: widget.accentColor,
                  ),
                ),

                Positioned(
                  bottom: AppConstants.spacingSm,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity:  _isDragging ? 0.0 : 0.90,
                      duration: const Duration(milliseconds: 180),
                      child: _DragHintBadge(isDark: widget.isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Address footer ──────────────────────────────────────────
        _AddressFooter(
          address:     widget.address,
          isDragging:  _isDragging,
          isGeocoding: widget.isGeocoding,
          isLocating:  widget.isLocating,
          accentColor: widget.accentColor,
          isDark:      widget.isDark,
        ),
      ],
    );
  }
}

// ── Crosshair pin ─────────────────────────────────────────────────────────────

class _CrosshairPin extends StatelessWidget {
  final bool  isDragging;
  final bool  isLocating;
  final Color accentColor;

  const _CrosshairPin({
    required this.isDragging,
    required this.isLocating,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  64,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve:    Curves.easeOut,
              width:    isDragging ? 10.0 : 20.0,
              height:   isDragging ? 4.0  : 8.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black
                    .withValues(alpha: isDragging ? 0.10 : 0.22),
              ),
            ),
          ),

          AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve:    Curves.easeOut,
            padding:  EdgeInsets.only(bottom: isDragging ? 18.0 : 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width:  48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                    // Neutral depth shadow (not an accent glow); grows on drag
                    // so the pin reads as lifting off the map.
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:
                            isDragging ? 0.32 : 0.22),
                        blurRadius: isDragging ? 16 : 8,
                        offset:     Offset(0, isDragging ? 10 : 4),
                      ),
                    ],
                  ),
                  child: isLocating
                      ? const Center(
                          child: SizedBox(
                            width:  20,
                            height: 20,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size:  24,
                        ),
                ),
                Container(
                  width:  2,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drag hint badge ───────────────────────────────────────────────────────────

class _DragHintBadge extends StatelessWidget {
  final bool isDark;
  const _DragHintBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd - 2,
        vertical:   AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.openWith,
            size:  11,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            context.tr('request_form.drag_to_adjust'),
            style: TextStyle(
              fontSize: AppConstants.fontSizeXxs,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address footer ────────────────────────────────────────────────────────────

class _AddressFooter extends StatelessWidget {
  final String address;
  final bool   isDragging;
  final bool   isGeocoding;
  final bool   isLocating;
  final Color  accentColor;
  final bool   isDark;

  const _AddressFooter({
    required this.address,
    required this.isDragging,
    required this.isGeocoding,
    required this.isLocating,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool showSpinner = isGeocoding || isLocating;

    final String text;
    if (isDragging)       text = context.tr('request_form.drag_to_adjust');
    else if (isLocating)  text = context.tr('request_form.location_detecting');
    else if (isGeocoding) text = context.tr('request_form.location_detecting');
    else if (address.isNotEmpty) text = address;
    else text = context.tr('request_form.location_idle');

    final Color textColor =
        isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMd,
        vertical:   AppConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.5)
            : AppTheme.lightSurface,
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showSpinner)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  end: AppConstants.spacingSm),
              child: SizedBox(
                width:  12,
                height: 12,
                child:  CircularProgressIndicator(
                    strokeWidth: 1.5, color: accentColor),
              ),
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  end: AppConstants.spacingSm),
              child: Icon(
                address.isNotEmpty && !isDragging
                    ? AppIcons.location
                    : AppIcons.locationSearch,
                size:  14,
                color: address.isNotEmpty && !isDragging
                    ? accentColor
                    : (isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppConstants.animDurationMicro,
              child: Text(
                text,
                key:   ValueKey(text),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:      textColor,
                      fontWeight: FontWeight.w400,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
