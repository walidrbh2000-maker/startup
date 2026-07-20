// lib/widgets/app_shimmer.dart
//
// The ONE skeleton system. Every loading placeholder in the app is built from
// [AppShimmer] wrapping a tree of [SkeletonBone]s — no per-screen
// AnimationControllers, no bespoke pulse tweens, no divergent colors.
//
// WHY the shimmer package (gradient sweep) and not an opacity pulse:
//   A sweep reads as "content streaming in"; a pulse reads as "something is
//   broken and blinking". The sweep is also cheaper here — one ShaderMask over
//   the whole subtree vs. one AnimationController per screen.
//
// HOW Shimmer works (so bones are built correctly):
//   Shimmer = ShaderMask(blendMode: srcATop) sweeping a LinearGradient
//   (baseColor → highlightColor) over its child. The child's pixels are the
//   ALPHA STENCIL: the gradient only paints where the child is opaque. So a
//   bone MUST be opaque white — its own color is irrelevant, only its opacity
//   and shape matter. The color the user sees is baseColor→highlightColor.
//
// Colors derive from the active ColorScheme via Color.alphaBlend (always
// alpha=255), so it's theme-proof in both light and dark with no constants.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color base = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.14),
      scheme.surface,
    );
    final Color shine = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.05),
      scheme.surface,
    );
    return Shimmer.fromColors(
      baseColor:      base,
      highlightColor: shine,
      period:         const Duration(milliseconds: 1400),
      child:          child,
    );
  }
}

/// A single skeleton bone. Must be opaque white — it is the ShaderMask stencil
/// (see file header). `width: null` fills the cross axis (stretch parents).
class SkeletonBone extends StatelessWidget {
  final double? width;
  final double  height;
  final double  radius;
  final bool    circle;

  const SkeletonBone({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  (width == double.infinity) ? null : width,
      height: height,
      decoration: BoxDecoration(
        shape:        circle ? BoxShape.circle : BoxShape.rectangle,
        color:        Colors.white,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
