// lib/screens/service_request/widgets/step_confirm.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../providers/service_request_form_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'location_card.dart';
import 'priority_selector.dart';
import 'request_summary_card.dart';

// ============================================================================
// STEP 3 — CONFIRM: LOCATION + PRIORITY + SUMMARY
//

class StepConfirm extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String  address;
  final LocationDetectionStatus locationStatus;
  final bool    isGeocodingAddress;
  final ServicePriority priority;
  final String? serviceType;
  final DateTime  scheduledDate;
  final TimeOfDay scheduledTime;
  final int  mediaCount;
  final bool isDark;
  final Color accentColor;
  final VoidCallback                         onRetryLocation;
  final ValueChanged<String>                 onAddressChanged;
  final VoidCallback                         onGeocodeAddress;
  final ValueChanged<ServicePriority>        onPrioritySelected;
  final void Function(double lat, double lng) onMapLocationChanged;

  const StepConfirm({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.locationStatus,
    required this.isGeocodingAddress,
    required this.priority,
    required this.serviceType,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.mediaCount,
    required this.isDark,
    required this.accentColor,
    required this.onRetryLocation,
    required this.onAddressChanged,
    required this.onGeocodeAddress,
    required this.onPrioritySelected,
    required this.onMapLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.spacingMd,
        AppConstants.paddingMd,
        AppConstants.spacingXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('request_form.section_location'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            context.tr('request_form.confirm_subtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          LocationCard(
            latitude:             latitude,
            longitude:            longitude,
            address:              address,
            locationStatus:       locationStatus,
            isGeocodingAddress:   isGeocodingAddress,
            isDark:               isDark,
            accentColor:          accentColor,
            onRetry:              onRetryLocation,
            onAddressChanged:     onAddressChanged,
            onGeocode:            onGeocodeAddress,
            onMapLocationChanged: onMapLocationChanged,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          Text(
            context.tr('request_form.section_priority'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          PrioritySelector(
            selected:  priority,
            isDark:    isDark,
            onChanged: onPrioritySelected,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          Text(
            context.tr('request_form.section_summary'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          RequestSummaryCard(
            serviceType:   serviceType,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            mediaCount:    mediaCount,
            priority:      priority,
            isDark:        isDark,
          ),
        ],
      ),
    );
  }
}
