// lib/screens/service_request/widgets/location_card.dart

import 'package:flutter/material.dart';

import '../../../providers/service_request_form_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'location_map_picker.dart';

// ============================================================================
// LOCATION CARD
// Wraps LocationMapPicker + optional manual address input + retry button.
//

class LocationCard extends StatefulWidget {
  final double?  latitude;
  final double?  longitude;
  final String   address;
  final LocationDetectionStatus locationStatus;
  final bool     isGeocodingAddress;
  final bool     isDark;
  final Color    accentColor;
  final VoidCallback                         onRetry;
  final ValueChanged<String>                 onAddressChanged;
  final VoidCallback                         onGeocode;
  final void Function(double lat, double lng) onMapLocationChanged;

  const LocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.locationStatus,
    required this.isGeocodingAddress,
    required this.isDark,
    required this.accentColor,
    required this.onRetry,
    required this.onAddressChanged,
    required this.onGeocode,
    required this.onMapLocationChanged,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  bool _manualMode = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.address);
  }

  @override
  void didUpdateWidget(LocationCard old) {
    super.didUpdateWidget(old);
    if (widget.address != old.address) {
      _ctrl.text = widget.address;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _detected =>
      widget.locationStatus == LocationDetectionStatus.detected;
  bool get _failed =>
      widget.locationStatus == LocationDetectionStatus.denied ||
      widget.locationStatus == LocationDetectionStatus.error;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animDurationShort,
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.6)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: _detected
              ? widget.accentColor.withValues(alpha: 0.40)
              : _failed
                  ? AppTheme.signOutRed.withValues(alpha: 0.35)
                  : (widget.isDark
                      ? AppTheme.darkCardBorderOverlay
                      : AppTheme.lightCardBorderOverlay),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Interactive drag-to-pin map
            LocationMapPicker(
              latitude:          widget.latitude,
              longitude:         widget.longitude,
              address:           widget.address,
              isDark:            widget.isDark,
              accentColor:       widget.accentColor,
              isLocating:        widget.locationStatus ==
                  LocationDetectionStatus.detecting,
              isGeocoding:       widget.isGeocodingAddress,
              onLocationChanged: widget.onMapLocationChanged,
            ),

            // Manual input + retry
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingMd,
                AppConstants.spacingXs,
                AppConstants.paddingMd,
                AppConstants.paddingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _manualMode = !_manualMode),
                        child: Text(
                          _manualMode
                              ? context.tr('common.back')
                              : context.tr('request_form.address_label'),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: widget.isDark
                                    ? AppTheme.darkAccentText
                                    : widget.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),

                  if (_manualMode || _failed) ...[
                    const SizedBox(height: AppConstants.spacingSm),
                    TextField(
                      controller:      _ctrl,
                      onChanged:       widget.onAddressChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted:     (_) => widget.onGeocode(),
                      decoration: InputDecoration(
                        hintText: context.tr('request_form.address_hint'),
                        prefixIcon:
                            const Icon(AppIcons.location, size: 18),
                        suffixIcon: widget.isGeocodingAddress
                            ? const SizedBox(
                                width:  18,
                                height: 18,
                                child:  Padding(
                                  padding: EdgeInsets.all(14.0),
                                  child:  CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search_rounded),
                                onPressed: widget.onGeocode,
                              ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMd,
                          vertical:   AppConstants.spacingMd,
                        ),
                      ),
                    ),
                  ],

                  if (_failed && !_manualMode) ...[
                    const SizedBox(height: AppConstants.spacingSm),
                    Semantics(
                      button: true,
                      label:  context.tr('common.retry'),
                      child: GestureDetector(
                        onTap: widget.onRetry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMd,
                            vertical:   AppConstants.spacingSm + 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.signOutRed.withValues(alpha: 0.09),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusMd),
                            border: Border.all(
                              color:
                                  AppTheme.signOutRed.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded,
                                  size: 15, color: AppTheme.signOutRed),
                              const SizedBox(width: 5),
                              Text(
                                context.tr('common.retry'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:      AppTheme.signOutRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
