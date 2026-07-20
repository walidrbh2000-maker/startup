// lib/screens/splash/widgets/splash_hairline_loader.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

const double _kTrackWidth = 96.0;
const double _kTrackHeight = 2.0;
const double _kSegmentWidth = 28.0;
const Duration _kSweepDuration = Duration(milliseconds: 1100);
const Duration _kSweepRest = Duration(milliseconds: 200);

/// A single indeterminate hairline: a 96×2dp accent-halo track with a solid
/// accent segment sweeping across it. AlignmentDirectional makes the sweep
/// travel right→left in RTL locales for free.
class SplashHairlineLoader extends StatefulWidget {
  final bool isDark;

  /// Localized "Loading…" label announced by screen readers.
  final String label;

  /// Renders a static centered hairline instead of the sweep.
  final bool reduceMotion;

  const SplashHairlineLoader({
    super.key,
    required this.isDark,
    required this.label,
    this.reduceMotion = false,
  });

  @override
  State<SplashHairlineLoader> createState() => _SplashHairlineLoaderState();
}

class _SplashHairlineLoaderState extends State<SplashHairlineLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<AlignmentGeometry> _alignment;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kSweepDuration + _kSweepRest,
    );
    // Sweep occupies the first 1100ms of the period; the remaining 200ms
    // holds the segment at the end — a breath between passes.
    _alignment = Tween<AlignmentGeometry>(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0,
          _kSweepDuration.inMilliseconds /
              (_kSweepDuration + _kSweepRest).inMilliseconds,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );
    if (!widget.reduceMotion) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackColor =
        widget.isDark ? AppTheme.darkAccentHalo : AppTheme.lightAccentHalo;
    final accent =
        widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    final segment = Container(
      width: widget.reduceMotion ? _kTrackWidth : _kSegmentWidth,
      height: _kTrackHeight,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(_kTrackHeight / 2),
      ),
    );

    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Container(
          width: _kTrackWidth,
          height: _kTrackHeight,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(_kTrackHeight / 2),
          ),
          child: widget.reduceMotion
              ? segment
              : AlignTransition(alignment: _alignment, child: segment),
        ),
      ),
    );
  }
}
