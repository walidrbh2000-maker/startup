// lib/screens/splash/widgets/splash_status_slot.dart

import 'package:flutter/material.dart';

import '../../../providers/splash_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'splash_hairline_loader.dart';

const double _kSlotWidth = 280.0;

/// Fixed-size area below the wordmark that cross-fades between the hairline
/// loader and the error state. Because its size never changes, the wordmark
/// above it never reflows — the brand stays put through every transition.
class SplashStatusSlot extends StatelessWidget {
  final SplashState state;
  final bool isDark;
  final bool reduceMotion;
  final VoidCallback onRetry;

  const SplashStatusSlot({
    super.key,
    required this.state,
    required this.isDark,
    required this.reduceMotion,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kSlotWidth,
      height: AppConstants.splashStatusAreaHeight,
      child: AnimatedSwitcher(
        duration: AppConstants.animDurationMicro,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: state.canRetry
            ? _ErrorContent(
                key: ValueKey(state.errorType),
                errorType: state.errorType,
                isDark: isDark,
                onRetry: onRetry,
              )
            : Align(
                key: const ValueKey('loading'),
                alignment: Alignment.topCenter,
                child: SplashHairlineLoader(
                  isDark: isDark,
                  label: context.tr('common.loading'),
                  reduceMotion: reduceMotion,
                ),
              ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final SplashErrorType errorType;
  final bool isDark;
  final VoidCallback onRetry;

  const _ErrorContent({
    super.key,
    required this.errorType,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;

    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(_icon, size: AppConstants.iconSizeSm, color: errorColor),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            context.tr('splash.${_key}_title'),
            style: textTheme.labelLarge,
            maxLines: 1,
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            context.tr('splash.$_key'),
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                AppConstants.splashRetryButtonMinWidth,
                AppConstants.buttonHeightMd,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMdLg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              textStyle: textTheme.labelLarge?.copyWith(color: null),
            ),
            child: Text(context.tr('common.retry')),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (errorType) {
      case SplashErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case SplashErrorType.serverError:
        return Icons.cloud_off_rounded;
      case SplashErrorType.timeout:
        return Icons.hourglass_empty_rounded;
      case SplashErrorType.unknown:
      case SplashErrorType.none:
        return Icons.error_outline_rounded;
    }
  }

  /// Localization key suffix — `splash.<key>` is the message,
  /// `splash.<key>_title` the one-line headline.
  String get _key {
    switch (errorType) {
      case SplashErrorType.noInternet:
        return 'error_no_internet';
      case SplashErrorType.serverError:
        return 'error_server';
      case SplashErrorType.timeout:
        return 'error_timeout';
      case SplashErrorType.unknown:
      case SplashErrorType.none:
        return 'error_message';
    }
  }
}
