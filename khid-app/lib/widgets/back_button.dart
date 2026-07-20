// lib/widgets/back_button.dart
//
// Universal back-navigation button used across all non-AppBar screens.
//
// Design: 48×48dp rounded-square icon button — Midnight Indigo design system.
//
// USAGE VARIANTS:
//
//   1. Standard (most screens):
//      AppBackButton(isDark: isDark)
//
//   2. With border (service-request form header):
//      AppBackButton(isDark: isDark, withBorder: true)
//
//   3. Form-step navigation (secondary color + border + custom action):
//      AppBackButton(
//        isDark: isDark,
//        withBorder: true,
//        useSecondaryColor: true,
//        onPressed: onBack,
//      )
//
//   4. Custom action (e.g. go-router push):
//      AppBackButton(isDark: isDark, onPressed: () => context.go('/home'))
//
// NOTE: For AppBar / SliverAppBar leading slots, use [AppBarBackButton] (below).
// It wraps the standard Material IconButton — correct for those slots — while
// guaranteeing the Semantics label + tooltip a11y contract on every screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

/// Safe universal back navigation.
///
/// Pops when there is history; otherwise lands on [fallback] (home by
/// default). Never throws and never silently does nothing — a screen reached
/// with `go()` (notification deep link, cold start, wizard `go()` chain) has
/// an empty stack, where a raw `context.pop()` throws a GoError and
/// `Navigator.maybePop` dead-ends. This is the ONE back primitive every
/// back affordance in the app must route through.
void appBack(BuildContext context, {String fallback = AppRoutes.home}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}

/// System-back guard for screens reachable with `go()` (empty stack — e.g.
/// notification deep links restored from cold start). Mirrors [appBack]:
/// pops normally when there is history, otherwise lands on [fallback]
/// instead of exiting the app.
class AppBackGuard extends StatelessWidget {
  final String fallback;
  final Widget child;

  const AppBackGuard({
    super.key,
    this.fallback = AppRoutes.home,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: GoRouter.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) GoRouter.of(context).go(fallback);
      },
      child: child,
    );
  }
}

class AppBackButton extends StatelessWidget {
  /// Custom tap handler. When null, defaults to [appBack] (pop or home).
  final VoidCallback? onPressed;

  /// Explicit theme override. When null, reads from [Theme.of(context)].
  final bool? isDark;

  /// Renders a subtle border around the button.
  /// Use in the service-request form header and form-step navigation.
  final bool withBorder;

  /// Uses [AppTheme.darkSecondaryText] / [AppTheme.lightSecondaryText]
  /// for the icon colour instead of the primary text colour.
  /// Use in form-step navigation where the back arrow is de-emphasised.
  final bool useSecondaryColor;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.isDark,
    this.withBorder = false,
    this.useSecondaryColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;

    final iconColor = useSecondaryColor
        ? (dark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText)
        : (dark ? AppTheme.darkText : AppTheme.lightText);

    final bgColor =
        (dark ? Colors.white : Colors.black).withValues(alpha: 0.07);

    final borderColor =
        (dark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Semantics(
      button: true,
      label: context.tr('common.back'),
      child: GestureDetector(
        onTap: onPressed ?? () => appBack(context),
        child: Container(
          width: AppConstants.backButtonSize,   // 48dp
          height: AppConstants.backButtonSize,  // 48dp
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: withBorder
                ? Border.all(
                    color: borderColor,
                    width: AppConstants.borderWidthDefault,
                  )
                : null,
          ),
          child: Icon(
            AppIcons.back,
            size: AppConstants.iconSizeSm,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// Back button for Material [AppBar] / [SliverAppBar] `leading` slots.
///
/// A standard Material [IconButton] (correct for those slots) that always
/// carries the Semantics label + tooltip a11y contract, so every AppBar screen
/// exposes an identical back affordance.
///
///   leading: const AppBarBackButton(),                       // appBack()
///   leading: AppBarBackButton(onPressed: () => context.go(...)),
class AppBarBackButton extends StatelessWidget {
  /// Custom tap handler. When null, defaults to [appBack] (pop or home).
  final VoidCallback? onPressed;

  const AppBarBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  context.tr('common.back'),
      child: IconButton(
        icon:      const Icon(AppIcons.back),
        tooltip:   context.tr('common.back'),
        onPressed: onPressed ?? () => appBack(context),
      ),
    );
  }
}
