// lib/screens/worker_jobs/widgets/browse_card_icon_button.dart

import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

// ============================================================================
// BROWSE CARD ICON BUTTON
// Circular 36×36 action button used in AvailableRequestCard (location, phone).
// Matches the 36×36 placeholder reserved by JobsSkeletonCard.
// ============================================================================

class BrowseCardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String semanticsLabel;
  final VoidCallback onTap;

  const BrowseCardIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: AppConstants.iconSizeSm,
            color: color,
          ),
        ),
      ),
    );
  }
}
