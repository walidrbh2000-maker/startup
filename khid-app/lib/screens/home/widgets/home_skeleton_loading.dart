// lib/screens/home/widgets/home_skeleton_loading.dart
//
// Home loading placeholder. Layout only — the shimmer mechanism and colors
// live in the shared [AppShimmer] / [SkeletonBone] primitives.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../widgets/app_shimmer.dart';

const double _kBarHeight   = 48.0;
const double _kAiBtnHeight = 32.0;
const double _kCardW       = 72.0;
const double _kCardH       = 80.0;
const double _kHeroCardH   = 150.0; // matches HomeHeroCarousel card height

class HomeSkeletonLoading extends StatelessWidget {
  const HomeSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: AppShimmer(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SkeletonTopBar(),
                const _SkeletonSearchSection(),
                const _SkeletonServicesSection(),
                const SizedBox(height: AppConstants.fabClearance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTopBar extends StatelessWidget {
  const _SkeletonTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top:    AppConstants.heroPaddingTop,
        left:   AppConstants.heroPaddingH,
        right:  AppConstants.heroPaddingH,
        bottom: AppConstants.heroPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonBone(width: 72, height: 12, radius: 4),
              Spacer(),
              SkeletonBone(width: 38, height: 38, circle: true),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          // Hero carousel card + page dots — mirrors HomeHeroCarousel.
          const SkeletonBone(
              width: double.infinity, height: _kHeroCardH,
              radius: AppConstants.radiusCard),
          const SizedBox(height: AppConstants.spacingSm),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBone(width: 18, height: 6, radius: 3),
              SizedBox(width: AppConstants.spacingXs),
              SkeletonBone(width: 6, height: 6, radius: 3),
              SizedBox(width: AppConstants.spacingXs),
              SkeletonBone(width: 6, height: 6, radius: 3),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          const Row(
            children: [
              SkeletonBone(width: 13, height: 13, circle: true),
              SizedBox(width: AppConstants.spacingXs),
              SkeletonBone(width: 160, height: 12, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonSearchSection extends StatelessWidget {
  const _SkeletonSearchSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBone(
              width: double.infinity, height: _kBarHeight,
              radius: AppConstants.radiusCircle),
          SizedBox(height: AppConstants.spacingSm),
          SkeletonBone(
              width: 130, height: _kAiBtnHeight,
              radius: AppConstants.radiusCircle),
        ],
      ),
    );
  }
}

class _SkeletonServicesSection extends StatelessWidget {
  const _SkeletonServicesSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.paddingMd,
        AppConstants.paddingLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBone(width: 90, height: AppConstants.spacingSm, radius: 4),
              SkeletonBone(width: 52, height: AppConstants.spacingSm, radius: 4),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          SizedBox(
            height: _kCardH,
            child: ListView.separated(
              scrollDirection:  Axis.horizontal,
              physics:          const NeverScrollableScrollPhysics(),
              itemCount:        5,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppConstants.spacingChipGap),
              itemBuilder: (_, __) => const SkeletonBone(
                  width: _kCardW, height: _kCardH, radius: AppConstants.radiusLg),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppConstants.paddingMd),
            child: SkeletonBone(width: double.infinity, height: 1, radius: 1),
          ),
          const SkeletonBone(
            width:  double.infinity,
            height: AppConstants.buttonHeight,
            radius: AppConstants.radiusLg,
          ),
        ],
      ),
    );
  }
}
