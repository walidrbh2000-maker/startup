// lib/screens/home/widgets/home_hero_carousel.dart
//
// Auto-advancing hero cards (offers / services / trust) — endless loop via a
// large virtual page offset brought back to 3 by modulo. A manual swipe
// simply re-arms the timer. No external carousel lib.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

const double _kCardHeight     = 150.0;
const double _kDotW           = 6.0;
const double _kDotWActive     = 18.0;
const double _kIconCircle     = 56.0;

/// How much a card shrinks as it leaves the viewport center (scroll-linked,
/// tracks the finger 1:1 — the standard "depth" treatment on hero carousels).
const double _kSideCardScale  = 0.06;

class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({super.key});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  static const int _cardCount = 3;
  static const int _initialPage = _cardCount * 1000;
  static const Duration _interval = Duration(seconds: 4);

  late final PageController _controller;
  Timer? _timer;
  int _page = _initialPage;

  /// Autoplay is disabled under reduced motion (autonomous movement is a
  /// vestibular trigger) and under screen readers (the page would advance
  /// while TalkBack/VoiceOver is mid-announcement). Resolved from MediaQuery,
  /// so it lives in didChangeDependencies rather than initState.
  bool _autoplayAllowed = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.88,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allowed = !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    if (allowed == _autoplayAllowed && _timer != null) return;
    _autoplayAllowed = allowed;
    if (allowed) {
      _startAutoScroll();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startAutoScroll() {
    if (!_autoplayAllowed) return;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!_controller.hasClients) return;
      _controller.nextPage(
        duration: AppConstants.animDurationPageTurn,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    // Point Final: one restrained accent across all cards; the icon is the
    // per-card differentiator, not a second hue.
    final cards = <_HeroCardData>[
      _HeroCardData(
        icon: Icons.handyman_rounded,
        title: context.tr('home.carousel_1_title'),
        subtitle: context.tr('home.carousel_1_subtitle'),
      ),
      _HeroCardData(
        icon: Icons.grid_view_rounded,
        title: context.tr('home.carousel_2_title'),
        subtitle: context.tr('home.carousel_2_subtitle'),
      ),
      _HeroCardData(
        icon: Icons.verified_rounded,
        title: context.tr('home.carousel_3_title'),
        subtitle: context.tr('home.carousel_3_subtitle'),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _kCardHeight,
          child: NotificationListener<ScrollStartNotification>(
            // dragDetails != null → user-initiated swipe: re-arm the timer so
            // the next auto-advance doesn't fire immediately after the gesture.
            onNotification: (n) {
              if (n.dragDetails != null) _startAutoScroll();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final card = Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingXs),
                  child: _HeroCard(
                      data: cards[index % _cardCount], accent: accent),
                );
                if (MediaQuery.disableAnimationsOf(context)) return card;
                // Scroll-linked depth: the centered card sits at full size,
                // neighbours recede as they leave the viewport center. Tracks
                // the finger 1:1 — transform-only, no relayout per frame.
                return AnimatedBuilder(
                  animation: _controller,
                  child: card,
                  builder: (context, child) {
                    double delta = 0;
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      delta = ((_controller.page ?? _page.toDouble()) - index)
                          .clamp(-1.0, 1.0);
                    }
                    return Transform.scale(
                      scale: 1.0 - _kSideCardScale * delta.abs(),
                      child: child,
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Semantics(
          label: '${_page % _cardCount + 1} / $_cardCount',
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cardCount, (i) {
            final active = i == _page % _cardCount;
            return AnimatedContainer(
              duration: AppConstants.animDurationShort,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? _kDotWActive : _kDotW,
              height: _kDotW,
              decoration: BoxDecoration(
                color: active
                    ? accent
                    : accent.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(_kDotW / 2),
              ),
            );
          }),
          ),
        ),
      ],
    );
  }
}

class _HeroCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _HeroCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _HeroCard extends StatelessWidget {
  final _HeroCardData data;
  final Color accent;
  const _HeroCard({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      // Flat accent surface — no gradient, no colored glow.
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Container(
            width: _kIconCircle,
            height: _kIconCircle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(data.icon, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}
