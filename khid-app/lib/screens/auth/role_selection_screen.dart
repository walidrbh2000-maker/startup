// lib/screens/auth/role_selection_screen.dart
//
// Role selector shown to new users after phone auth — large tappable cards
// (client / worker / business) with scale-on-press feedback.
//
// BACK BEHAVIOR: the stack is empty here (reached with go() after OTP), so
// "back" can't pop. Both the header back button and the system back gesture
// sign out and return to phone auth — the WhatsApp-style "wrong number /
// different account" escape. Without this the screen is a trap.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/settings_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/back_button.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_submit_button.dart';

// ─────────────────────────────────────────────────────────────────────────────

enum _Role { client, worker, business }

class _RoleData {
  final _Role    role;
  final IconData icon;
  final String   titleKey;
  final String   subtitleKey;

  const _RoleData({
    required this.role,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });
}

const List<_RoleData> _kRoles = [
  _RoleData(
    role:        _Role.client,
    icon:        AppIcons.search,
    titleKey:    'role_selection.client_title',
    subtitleKey: 'role_selection.client_subtitle',
  ),
  _RoleData(
    role:        _Role.worker,
    icon:        AppIcons.build,
    titleKey:    'role_selection.worker_title',
    subtitleKey: 'role_selection.worker_subtitle',
  ),
  _RoleData(
    role:        _Role.business,
    icon:        Icons.business_center_rounded,
    titleKey:    'role_selection.business_title',
    subtitleKey: 'role_selection.business_subtitle',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {

  _Role? _selected;
  bool   _leaving = false;

  late final AnimationController _slideController;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync:    this,
      duration: AppConstants.authCardEntranceDuration,
    )..forward();

    _fadeAnim  = CurvedAnimation(parent: _slideController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _selectRole(_Role role) {
    HapticFeedback.selectionClick();
    setState(() => _selected = role);
  }

  /// Sign out and return to phone auth ("wrong number / another account").
  /// The router's redirect reacts to the auth change and lands on /phone-auth.
  Future<void> _backToPhoneAuth() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await ref.read(settingsProvider.notifier).signOut();
    // Normally the redirect unmounts this screen; if sign-out failed
    // (offline) re-arm the button instead of leaving it dead.
    if (mounted) setState(() => _leaving = false);
  }

  void _onContinue() {
    if (_selected == null) return;
    HapticFeedback.mediumImpact();

    // Business reuses the client profile-setup flow; the account type is carried
    // as a query param and persisted as role='business' on submit.
    final route = switch (_selected!) {
      _Role.worker   => AppRoutes.workerProfileSetup,
      _Role.business => '${AppRoutes.userProfileSetup}?type=business',
      _Role.client   => AppRoutes.userProfileSetup,
    };

    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _backToPhoneAuth();
        },
        child: Scaffold(
          body: Stack(
            children: [
              AuthBackground(isDark: isDark),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLg,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppConstants.paddingXl),

                          // Back — signs out to phone auth (another account).
                          Row(
                            children: [
                              AppBackButton(
                                isDark:    isDark,
                                onPressed: _leaving ? () {} : _backToPhoneAuth,
                              ),
                              const SizedBox(width: AppConstants.spacingMd),
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    context.tr('role_selection.title'),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppConstants.spacingSm),

                          Text(
                            context.tr('role_selection.subtitle'),
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeMd,
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText,
                            ),
                          ),

                          const SizedBox(height: AppConstants.spacingXl),

                          // Role cards
                          ...(_kRoles.map((data) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingMd,
                            ),
                            child: _RoleCard(
                              data:       data,
                              isDark:     isDark,
                              isSelected: _selected == data.role,
                              onTap:      () => _selectRole(data.role),
                            ),
                          ))),

                          const Spacer(),

                          // CTA
                          AnimatedOpacity(
                            duration: AppConstants.animDurationMicro,
                            opacity:  _selected != null ? 1.0 : 0.4,
                            child: AuthSubmitButton(
                              isLoading: false,
                              isDark:    isDark,
                              onPressed: _selected != null ? _onContinue : null,
                              labelKey:  'common.next',
                            ),
                          ),

                          const SizedBox(height: AppConstants.spacingLg),
                        ],
                      ),
                    ),
                  ),
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
// Role card
// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final _RoleData    data;
  final bool         isDark;
  final bool         isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.data,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pressController;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync:    this,
      duration: AppConstants.animDurationPress,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One app accent for every role card — roles differ by icon and copy,
    // selection by border colour/width (Point Final: no per-card tints).
    final accent =
        widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button:   true,
      selected: widget.isSelected,
      label:    context.tr(widget.data.titleKey),
      child: GestureDetector(
        onTapDown:  (_) => _pressController.forward(),
        onTapUp:    (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap:      widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: AppConstants.animDurationMicro,
            curve:    Curves.easeOut,
            padding: const EdgeInsets.all(AppConstants.paddingXl),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? accent.withValues(alpha: widget.isDark ? 0.12 : 0.08)
                  : (widget.isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              border: Border.all(
                color: widget.isSelected
                    ? accent
                    : (widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                width: widget.isSelected
                    ? AppConstants.borderWidthSelected
                    : AppConstants.borderWidthDefault,
              ),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width:  AppConstants.iconContainerFeature,
                  height: AppConstants.iconContainerFeature,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(
                        alpha: widget.isSelected ? 0.20 : 0.12),
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: accent,
                    size:  AppConstants.iconSizeMd,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingMd),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(widget.data.titleKey),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.isSelected
                              ? accent
                              : (widget.isDark ? AppTheme.darkText : AppTheme.lightText),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        context.tr(widget.data.subtitleKey),
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeSm,
                          color: widget.isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Check indicator
                AnimatedOpacity(
                  duration: AppConstants.animDurationMicro,
                  opacity:  widget.isSelected ? 1.0 : 0.0,
                  child: Icon(
                    AppIcons.check,
                    color: accent,
                    size:  AppConstants.iconSizeSm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
