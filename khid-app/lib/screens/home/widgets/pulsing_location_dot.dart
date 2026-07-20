// lib/screens/home/widgets/pulsing_location_dot.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ============================================================================
// PULSING LOCATION DOT
// ============================================================================

class PulsingLocationDot extends StatefulWidget {
  const PulsingLocationDot({super.key});

  @override
  State<PulsingLocationDot> createState() => _PulsingLocationDotState();
}

class _PulsingLocationDotState extends State<PulsingLocationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _opacity;

  static const Color _dotColor = AppTheme.mapLocationBlue;

  // Integer width — non-integer borders bleed sub-pixel on 1x screens.
  static const double _kBorderWidth = 2.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scale = Tween<double>(begin: 0.6, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onPrimary;

    final double dotSize = AppConstants.locationDotSize;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple ring
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width:  dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor.withValues(alpha: _opacity.value),
              ),
            ),
          ),
        ),

        // Solid dot
        Container(
          width:  dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            color:  _dotColor,
            border: Border.all(color: borderColor, width: _kBorderWidth),
          ),
        ),
      ],
    );
  }
}
