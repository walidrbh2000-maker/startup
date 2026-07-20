// lib/screens/home/widgets/location_address_display.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../widgets/app_shimmer.dart';

const double _kShimmerW = 120.0;
const double _kShimmerH =  12.0;

// ============================================================================
// LOCATION ADDRESS DISPLAY
// ============================================================================

class LocationAddressDisplay extends StatelessWidget {
  final String? address;

  const LocationAddressDisplay({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    if (address == null || address!.isEmpty) {
      return const _AddressShimmer();
    }
    return _AddressText(address: address!);
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _AddressShimmer extends StatelessWidget {
  const _AddressShimmer();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: SkeletonBone(
        width:  _kShimmerW,
        height: _kShimmerH,
        radius: AppConstants.radiusXs,
      ),
    );
  }
}

// ── Resolved text ─────────────────────────────────────────────────────────────

class _AddressText extends StatefulWidget {
  final String address;

  const _AddressText({super.key, required this.address});

  @override
  State<_AddressText> createState() => _AddressTextState();
}

class _AddressTextState extends State<_AddressText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppTheme.darkAccent    : AppTheme.lightAccent;
    final textColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return FadeTransition(
      opacity: _fade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.location, size: 13, color: iconColor),
          const SizedBox(width: AppConstants.spacingXs),
          Flexible(
            child: Text(
              widget.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:      textColor,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
