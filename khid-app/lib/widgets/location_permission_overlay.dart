// lib/widgets/location_permission_overlay.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_lifecycle_provider.dart';
import '../providers/home_controller.dart';
import '../providers/location_permission_controller.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../utils/logger.dart';

// ============================================================================
// TYPEDEF
// ============================================================================

typedef _PermProvider = AutoDisposeStateNotifierProvider<
    LocationPermissionController, LocationPermissionState>;

// ─── Feature-specific dimensions ─────────────────────────────────────────────
const double _kIllustrationSize = 120.0;
const double _kCardRadius       = 28.0;
const double _kButtonHeight     = 52.0;

// ============================================================================
// LOCATION PERMISSION GATE
// ============================================================================

class LocationPermissionGate extends ConsumerStatefulWidget {
  final Widget child;
  const LocationPermissionGate({super.key, required this.child});

  @override
  ConsumerState<LocationPermissionGate> createState() =>
      _LocationPermissionGateState();
}

class _LocationPermissionGateState
    extends ConsumerState<LocationPermissionGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double>   _backdropFade;
  late final Animation<Offset>   _cardSlide;

  bool _overlayVisible = false;

  static final _provider =
      locationPermissionControllerProvider as _PermProvider;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 380),
    );
    _backdropFade = CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOut,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialState = ref.read(_provider);
      if (!initialState.isChecking &&
          !initialState.isGranted &&
          !initialState.isSkipped) {
        AppLogger.info(
            'LocationPermissionGate: showing overlay for initial state '
            '${initialState.permissionStatus}');
        _showOverlay();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (!_overlayVisible) {
      setState(() => _overlayVisible = true);
      _animController.forward();
    }
  }

  void _hideOverlay() {
    _animController.reverse().then((_) {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final permState = ref.watch(_provider);

    ref.listen(appLifecycleProvider, (_, next) {
      if (next == AppLifecycleStateEnum.resumed) {
        ref.read(_provider.notifier).recheck();
        AppLogger.info('LocationPermissionGate: re-checking on resume');
      }
    });

    ref.listen<LocationPermissionState>(_provider, (_, next) {
      if (!next.isChecking && !next.isGranted && !next.isSkipped) {
        _showOverlay();
      } else if (next.isGranted || next.isSkipped) {
        _hideOverlay();
      }
    });

    ref.listen<bool>(
      homeControllerProvider.select((s) => s.isMapFullscreen),
      (_, isFullscreen) {
        if (isFullscreen) {
          ref.read(_provider.notifier).triggerIfSkipped();
        }
      },
    );

    return Stack(
      children: [
        widget.child,

        // Loading bar
        if (permState.isChecking)
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkAccent),
              minHeight: 3,
            ),
          ),

        // Backdrop — flat dark overlay, no BackdropFilter
        if (_overlayVisible)
          Positioned.fill(
            child: FadeTransition(
              opacity: _backdropFade,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap:    null,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),

        // Bottom card
        if (_overlayVisible)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: _LocationPermissionCard(
                permState:      permState,
                onRequest:      () =>
                    ref.read(_provider.notifier).requestPermission(),
                onOpenSettings: () =>
                    ref.read(_provider.notifier).openSettings(),
                onDismiss: () {
                  ref.read(_provider.notifier).dismiss();
                  _hideOverlay();
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// PERMISSION CARD
// ============================================================================

class _LocationPermissionCard extends StatefulWidget {
  final LocationPermissionState permState;
  final VoidCallback            onRequest;
  final VoidCallback            onOpenSettings;
  final VoidCallback            onDismiss;

  const _LocationPermissionCard({
    required this.permState,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  @override
  State<_LocationPermissionCard> createState() =>
      _LocationPermissionCardState();
}

class _LocationPermissionCardState extends State<_LocationPermissionCard>
    with TickerProviderStateMixin {
  late final AnimationController _pinCtrl;
  late final Animation<double>   _pinBounce;
  late final Animation<double>   _pinScale;

  late final AnimationController _rippleCtrl;
  late final Animation<double>   _ripple1;
  late final Animation<double>   _ripple2;
  late final Animation<double>   _ripple3;

  late final AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();

    _pinCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    );
    _pinBounce = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(parent: _pinCtrl, curve: Curves.bounceOut),
    );
    _pinScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _pinCtrl,
        curve:  const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _rippleCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _ripple1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _rippleCtrl,
          curve:  const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _ripple2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _rippleCtrl,
          curve:  const Interval(0.25, 0.95, curve: Curves.easeOut)),
    );
    _ripple3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _rippleCtrl,
          curve:  const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _orbitCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _pinCtrl.forward();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _rippleCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accent       = isDark ? AppTheme.darkAccent    : AppTheme.lightAccent;
    final isPermanent  = widget.permState.needsSettings;
    final isRequesting = widget.permState.isRequesting;
    final theme        = Theme.of(context);

    final cardBg = isDark
        ? AppTheme.darkSurface.withValues(alpha: 0.98)
        : AppTheme.lightSurface.withValues(alpha: 0.98);

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_kCardRadius),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
            blurRadius: 40,
            offset:     const Offset(0, -8),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLg,
            AppConstants.paddingMd,
            AppConstants.paddingLg,
            AppConstants.paddingMd,
          ),
          child: Column(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle + Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  Center(
                    child: Container(
                      width:  40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:        theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        button: true,
                        label:  context.tr('permission.skip'),
                        child: GestureDetector(
                          onTap: widget.onDismiss,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              context.tr('permission.skip'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Illustration + Text
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CompactIllustration(
                    accent:      accent,
                    isPermanent: isPermanent,
                    pinBounce:   _pinBounce,
                    pinScale:    _pinScale,
                    ripple1:     _ripple1,
                    ripple2:     _ripple2,
                    ripple3:     _ripple3,
                    orbitCtrl:   _orbitCtrl,
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPermanent
                              ? context.tr('permission.denied_title')
                              : context.tr('permission.title'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight:    FontWeight.w700,
                            letterSpacing: -0.3,
                            height:        1.2,
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Text(
                          isPermanent
                              ? context.tr('permission.denied_body')
                              : context.tr('permission.body'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:  isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacingMd),

              Divider(
                height:    1,
                thickness: 1,
                color:     isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              if (!isPermanent) ...[
                _FeatureList(isDark: isDark, accent: accent),
                const SizedBox(height: AppConstants.spacingMd),
              ],

              // Primary button
              _PrimaryButton(
                label:     isPermanent
                    ? context.tr('permission.open_settings')
                    : context.tr('permission.allow'),
                icon:      isPermanent
                    ? Icons.settings_rounded
                    : Icons.location_on_rounded,
                color:     isPermanent
                    ? (isDark ? AppTheme.darkError : AppTheme.lightError)
                    : accent,
                isLoading: isRequesting,
                onTap:     isRequesting
                    ? null
                    : (isPermanent ? widget.onOpenSettings : widget.onRequest),
              ),

              // Secondary button
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: widget.onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLg),
                    ),
                  ),
                  child: Text(
                    context.tr('permission.not_now'),
                    style: const TextStyle(
                      fontSize:   AppConstants.fontSizeSm,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              // Privacy note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size:  11,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.tr('permission.privacy_note'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeXs,
                        color:    isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMPACT ILLUSTRATION
// ============================================================================

class _CompactIllustration extends StatelessWidget {
  final Color               accent;
  final bool                isPermanent;
  final Animation<double>   pinBounce;
  final Animation<double>   pinScale;
  final Animation<double>   ripple1;
  final Animation<double>   ripple2;
  final Animation<double>   ripple3;
  final AnimationController orbitCtrl;

  const _CompactIllustration({
    required this.accent,
    required this.isPermanent,
    required this.pinBounce,
    required this.pinScale,
    required this.ripple1,
    required this.ripple2,
    required this.ripple3,
    required this.orbitCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  _kIllustrationSize,
      height: _kIllustrationSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings
          ...[ripple1, ripple2, ripple3].map((r) => AnimatedBuilder(
                animation: r,
                builder: (_, __) => Container(
                  width:  _kIllustrationSize * r.value,
                  height: _kIllustrationSize * r.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: (1 - r.value) * 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
              )),

          // Orbit dot
          AnimatedBuilder(
            animation: orbitCtrl,
            builder: (_, __) {
              final angle = orbitCtrl.value * 2 * math.pi;
              const radius = 34.0;
              return Transform.translate(
                offset: Offset(
                  math.cos(angle) * radius,
                  math.sin(angle) * radius,
                ),
                child: Container(
                  width:  8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
              );
            },
          ),

          // Pin
          AnimatedBuilder(
            animation: pinBounce,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, pinBounce.value),
              child: ScaleTransition(
                scale: pinScale,
                child: child,
              ),
            ),
            child: Container(
              width:  isPermanent ? 42 : 36,
              height: isPermanent ? 42 : 36,
              decoration: BoxDecoration(
                color:  isPermanent
                    ? AppTheme.signOutRed
                    : accent,
                shape:  BoxShape.circle,
                // Neutral depth shadow, not an accent glow — same convention
                // as worker_map_marker / location_map_picker pins.
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                isPermanent
                    ? Icons.location_off_rounded
                    : Icons.location_on_rounded,
                color: Colors.white,
                size:  isPermanent ? 22 : 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FEATURE LIST
// ============================================================================

class _FeatureList extends StatelessWidget {
  final bool  isDark;
  final Color accent;

  const _FeatureList({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.search_rounded,  context.tr('permission.feature_search')),
      (Icons.near_me_rounded, context.tr('permission.feature_nearby')),
      (Icons.bolt_rounded,    context.tr('permission.feature_fast')),
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingXs + 2),
          child: Row(
            children: [
              Container(
                width:  28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.10),
                ),
                child: Icon(item.$1, size: 14, color: accent),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                item.$2,
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeSm,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// PRIMARY BUTTON
// ============================================================================

class _PrimaryButton extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final Color      color;
  final bool       isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: _kButtonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            color: onTap == null ? color.withValues(alpha: 0.38) : color,
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width:  22,
                    height: 22,
                    child:  CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: AppConstants.spacingXs + 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize:      AppConstants.fontSizeMd,
                        fontWeight:    FontWeight.w700,
                        color:         Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
