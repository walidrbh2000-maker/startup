// lib/screens/home/widgets/worker_map_marker.dart

import 'package:flutter/material.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import 'worker_preview_sheet.dart';

const double _kBadgeIconSize = 12.0;

// Thicker than borderWidthSelected: the best-worker pin must read at map scale.
const double _kBestMarkerBorderWidth = 3.0;

// ============================================================================
// MARKER
// ============================================================================

class WorkerMapMarker extends StatelessWidget {
  final WorkerModel worker;
  /// When true, renders a golden star marker — visually distinct from others.
  final bool isBest;

  const WorkerMapMarker({
    super.key,
    required this.worker,
    this.isBest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isBest
        ? AppTheme.warningAmber
        : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent);

    // profession is nullable on the wire — one malformed doc must not take
    // down the whole marker layer. 'other' maps to the generic icon.
    final icon = AppTheme.getProfessionIcon(worker.profession ?? 'other');
    final size = isBest ? 56.0 : 48.0;

    final borderColor = Theme.of(context).colorScheme.onPrimary;

    return GestureDetector(
      onTap: () => _showPreview(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            clipBehavior: Clip.none,
            children: [
              // Bubble
              Container(
                width:  size,
                height: size,
                decoration: BoxDecoration(
                  color:  color,
                  shape:  BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isBest
                        ? _kBestMarkerBorderWidth
                        : AppConstants.borderWidthSelected,
                  ),
                  // Neutral depth shadow — a map pin should read as *lifted*,
                  // not glowing. A saturated same-colour shadow at 55–70% blooms
                  // into a neon halo (worst on dark map tiles). Black at low alpha
                  // gives clean elevation; dark theme needs a touch more to read.
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
                      blurRadius: isBest ? 10 : 8,
                      offset:     const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: borderColor,
                  size:  isBest ? AppConstants.iconSizeMd : AppConstants.iconSizeSm,
                ),
              ),
              // Star badge — only on best worker
              if (isBest)
                Positioned(
                  top:   -4,
                  right: -4,
                  child: Container(
                    width:  AppConstants.iconSizeXs,
                    height: AppConstants.iconSizeXs,
                    decoration: BoxDecoration(
                      color: borderColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        AppIcons.ratingFilled,
                        size:  _kBadgeIconSize,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Triangle pointer
          CustomPaint(
            size:    const Size(12, 7),
            painter: _PointerPainter(color: color),
          ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context) {
    showModalBottomSheet(
      context:              context,
      backgroundColor:      Colors.transparent,
      isScrollControlled:   true,
      builder: (_) => WorkerPreviewSheet(worker: worker),
    );
  }
}

// ── Triangle pointer painter ──────────────────────────────────────────────────

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
