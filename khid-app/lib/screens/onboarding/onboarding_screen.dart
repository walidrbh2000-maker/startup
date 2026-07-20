// lib/screens/onboarding/onboarding_screen.dart
//
// "Point Final" chapter pages — the splash's typographic identity carried
// forward. No illustrations, no gradients, no icon orbs: each slide is an
// editorial chapter — an oversized ghost numeral, a short accent rule, a
// headline closed by the accent full stop (the brand gesture), and a
// two-line subtitle. Everything is start-aligned so RTL flips for free.
//
// The scaffold background is the plain theme background — identical to the
// splash — so the splash→onboarding handoff is seamless, and the mini
// wordmark in the top bar carries the brand from one screen to the next.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/onboarding_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/wordmark.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Slide content — pure data.
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterData {
  final String titleKey;
  final String subtitleKey;

  const _ChapterData({required this.titleKey, required this.subtitleKey});
}

// Editorial metrics — file-local, same convention as the splash widgets.
const double _kGhostNumeralSize = 96.0;
const double _kRuleHeight       = 2.0;   // progress-rule segment height
const double _kSegmentActiveW   = 32.0;
const double _kSegmentIdleW     = 14.0;
const double _kSegmentGap       = 6.0;

// Scroll-driven parallax factors (dp of travel at |page delta| = 1).
// The ghost numeral lags behind the page (background plane); the text block
// leads slightly ahead of it (foreground plane). Parallax is a vestibular
// trigger, so it is disabled entirely under reduced motion.
const double _kNumeralParallax = 56.0;
const double _kContentParallax = -18.0;

const List<_ChapterData> _kChapters = [
  _ChapterData(
    titleKey: 'onboarding.slide1_title',
    subtitleKey: 'onboarding.slide1_subtitle',
  ),
  _ChapterData(
    titleKey: 'onboarding.slide2_title',
    subtitleKey: 'onboarding.slide2_subtitle',
  ),
  _ChapterData(
    titleKey: 'onboarding.slide3_title',
    subtitleKey: 'onboarding.slide3_subtitle',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    if (_currentPage < _kChapters.length - 1) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        _pageController.nextPage(
          duration: AppConstants.animDurationPageTurn,
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingControllerProvider.notifier).markDone();
    if (mounted) context.go(AppRoutes.phoneAuth);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isLast = _currentPage == _kChapters.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                isDark: isDark,
                onSkip: isLast ? null : _finish,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemCount: _kChapters.length,
                  itemBuilder: (_, index) => _ChapterSlide(
                    index: index,
                    data: _kChapters[index],
                    isDark: isDark,
                    reduceMotion: reduceMotion,
                    controller: _pageController,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingXl,
                  AppConstants.spacingMd,
                  AppConstants.paddingXl,
                  AppConstants.spacingLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressRule(
                      count: _kChapters.length,
                      current: _currentPage,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        isLast
                            ? context.tr('onboarding.get_started')
                            : context.tr('onboarding.next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — mini wordmark start, skip end.
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onSkip;

  const _TopBar({required this.isDark, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXl,
        vertical: AppConstants.paddingSm,
      ),
      child: Row(
        children: [
          // Brand continuity from the splash wordmark.
          const AppWordmark(),
          const Spacer(),
          AnimatedOpacity(
            duration: AppConstants.animDurationMicro,
            opacity: onSkip != null ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: onSkip == null,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
                child: Text(context.tr('onboarding.skip')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter slide — ghost numeral, accent rule, headline + point final, subtitle.
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterSlide extends StatelessWidget {
  final int index;
  final _ChapterData data;
  final bool isDark;
  final bool reduceMotion;
  final PageController controller;

  const _ChapterSlide({
    required this.index,
    required this.data,
    required this.isDark,
    required this.reduceMotion,
    required this.controller,
  });

  /// Signed distance of this slide from the viewport center, in pages.
  /// 0 = fully settled, ±1 = fully off-screen.
  double _pageDelta() {
    if (!controller.hasClients || !controller.position.haveDimensions) {
      return 0.0;
    }
    return ((controller.page ?? index.toDouble()) - index).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Negative tracking breaks Arabic ligature shaping — same gate as the
    // splash wordmark.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final titleStyle = theme.textTheme.displaySmall?.copyWith(
      height: 1.2,
      letterSpacing: isArabic ? 0.0 : null,
    );

    // Oversized ghost numeral — editorial chapter index, background plane.
    Widget numeral = ExcludeSemantics(
      child: Text(
        '0${index + 1}',
        style: theme.textTheme.displayLarge?.copyWith(
          fontSize: _kGhostNumeralSize,
          fontWeight: FontWeight.w200,
          height: 1.0,
          letterSpacing: 0,
          color:
              isDark ? AppTheme.darkTertiaryText : AppTheme.lightTertiaryText,
        ),
      ),
    );
    // Accent rule — the hairline motif from the splash loader.
    Widget rule = const AccentRule();
    Widget title = Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          text: context.tr(data.titleKey),
          style: titleStyle,
          children: [
            TextSpan(
              text: '.',
              style: titleStyle?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
    Widget subtitle = Text(
      context.tr(data.subtitleKey),
      style: theme.textTheme.bodyLarge?.copyWith(
        color:
            isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
      ),
    );

    if (!reduceMotion) {
      // Staggered editorial entrance — replays when the page is revisited,
      // which reads as intentional rhythm rather than repetition. The numeral
      // settles from a slight oversize, the rule draws itself, the type rises.
      numeral = numeral
          .animate()
          .fadeIn(duration: 420.ms, curve: Curves.easeOut)
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1.0, 1.0),
            duration: 420.ms,
            curve: Curves.easeOutCubic,
          );
      rule = rule.animate().scaleX(
            begin: 0.0,
            end: 1.0,
            delay: 100.ms,
            duration: 340.ms,
            curve: Curves.easeOutCubic,
          );
      title = title
          .animate()
          .fadeIn(delay: 160.ms, duration: 420.ms, curve: Curves.easeOut)
          .moveY(
            begin: 14,
            end: 0,
            delay: 160.ms,
            duration: 420.ms,
            curve: Curves.easeOutCubic,
          );
      subtitle = subtitle
          .animate()
          .fadeIn(delay: 240.ms, duration: 420.ms, curve: Curves.easeOut)
          .moveY(
            begin: 14,
            end: 0,
            delay: 240.ms,
            duration: 420.ms,
            curve: Curves.easeOutCubic,
          );
    }

    Widget column(double numeralDx, double contentDx) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: Offset(numeralDx, 0),
              child: numeral,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Transform.translate(
              offset: Offset(contentDx, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  rule,
                  const SizedBox(height: AppConstants.spacingLg),
                  title,
                  const SizedBox(height: AppConstants.spacingMd),
                  subtitle,
                ],
              ),
            ),
          ],
        );

    final slide = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXl),
      child: reduceMotion
          ? column(0, 0)
          : AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final delta = _pageDelta();
                // PageView already mirrors its own translation under RTL;
                // the inner planes must mirror with it.
                final rtlSign =
                    Directionality.of(context) == TextDirection.rtl
                        ? -1.0
                        : 1.0;
                return Opacity(
                  opacity: (1.0 - delta.abs() * 0.6).clamp(0.0, 1.0),
                  child: column(
                    _kNumeralParallax * delta * rtlSign,
                    _kContentParallax * delta * rtlSign,
                  ),
                );
              },
            ),
    );
    return slide;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress rule — three hairline segments, the active one long and accented.
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRule extends StatelessWidget {
  final int count;
  final int current;
  final bool isDark;

  const _ProgressRule({
    required this.count,
    required this.current,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${current + 1} / $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final isActive = index == current;
          return AnimatedContainer(
            duration: AppConstants.animDurationMicro,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsetsDirectional.only(end: _kSegmentGap),
            width: isActive ? _kSegmentActiveW : _kSegmentIdleW,
            height: _kRuleHeight,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              borderRadius: BorderRadius.circular(_kRuleHeight / 2),
            ),
          );
        }),
      ),
    );
  }
}
