// lib/screens/settings/widgets/settings_content.dart
//
// The settings list: editorial header, hero profile card, and grouped rows.
// Nav icons are monochrome (accent is reserved for the brand mark, switches,
// and destructive actions) — the restrained Point Final palette.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/language_service.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/localization.dart';
import '../../../widgets/app_section_header.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/app_shimmer.dart';
import '../../../services/biometric_lock_service.dart';
import 'profile_card.dart';
import 'settings_tile.dart';
import 'sheet_option.dart';
import 'sign_out_tile.dart';

class SettingsContent extends ConsumerWidget {
  final SettingsState state;

  const SettingsContent({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme               = Theme.of(context);
    final languageService     = ref.read(languageServiceProvider);
    final currentLanguageName = ref.watch(currentLanguageNameProvider);
    final isActionInProgress  = state.isSigningOut || state.isDeletingAccount;
    final isGuest             = ref.watch(isGuestProvider);

    // Nav rows share one restrained icon colour — no rainbow chips. Accent is
    // reserved for the header mark, switches, and destructive rows. Uses the
    // palette's secondary-text tone (same muted colour FeatureErrorState uses).
    final mutedIcon = theme.brightness == Brightness.dark
        ? AppTheme.darkSecondaryText
        : AppTheme.lightSecondaryText;

    return ListView(
      padding: EdgeInsetsDirectional.only(
        // spacingChipGap (12.0) replaces the bare `+ 12` literal.
        top:    MediaQuery.of(context).padding.top + kToolbarHeight + AppConstants.spacingChipGap,
        bottom: MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight +
            AppConstants.spacingLg,
        start:  AppConstants.paddingMd,
        end:    AppConstants.paddingMd,
      ),
      children: [
        // Title lives in the AppBar row beside the back button (PointFinalTitle).

        if (isGuest)
          SettingsTile(
            icon:           AppIcons.person,
            iconColor:      theme.colorScheme.primary,
            title:          context.tr('auth.guest_gate_cta'),
            subtitle:       context.tr('auth.guest_gate_body'),
            semanticsLabel: context.tr('auth.guest_gate_cta'),
            // Drop the anonymous session; the router routes to phone auth.
            onTap:          () => ref.read(authServiceProvider).signOut(),
          )
        else if (state.status == SettingsStatus.loading)
          const _ProfileCardSkeleton()
        else
          ProfileCard(state: state),

        const SizedBox(height: AppConstants.spacingLg),

        AppSectionHeader(label: context.tr('settings.general')),
        const SizedBox(height: AppConstants.spacingSm),

        SettingsTile(
          icon:           AppIcons.language,
          iconColor:      mutedIcon,
          title:          context.tr('settings.language'),
          subtitle:       currentLanguageName,
          semanticsLabel: context.tr('settings.language'),
          onTap:          () => _showLanguageSheet(context, ref, languageService),
        ),

        SettingsTile(
          icon:           AppIcons.notifications,
          iconColor:      mutedIcon,
          title:          context.tr('settings.notifications'),
          semanticsLabel: context.tr('settings.notifications'),
          onTap:          () => context.push(AppRoutes.notifications),
        ),

        _BiometricLockTile(iconColor: mutedIcon),

        // Account PIN — server-side anti-SIM-recycling protection. Optional
        // but recommended; guests have no account to protect.
        if (!isGuest)
          SettingsTile(
            icon:           Icons.pin_outlined,
            iconColor:      mutedIcon,
            title:          context.tr('pin.title'),
            subtitle:       context.tr('pin.recommended'),
            semanticsLabel: context.tr('pin.title'),
            onTap:          () => context.push(AppRoutes.accountPin),
          ),

        Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            return SettingsTile(
              icon:           AppIcons.theme,
              iconColor:      mutedIcon,
              title:          context.tr('settings.theme'),
              subtitle:       _themeModeLabel(context, themeMode),
              semanticsLabel: context.tr('settings.theme'),
              onTap:          () => _showThemeSheet(context, ref, themeMode),
            );
          },
        ),

        const SizedBox(height: AppConstants.spacingMdLg),

        AppSectionHeader(label: context.tr('settings.account')),
        const SizedBox(height: AppConstants.spacingSm),

        if (!isGuest)
          SettingsTile(
            icon:           AppIcons.person,
            iconColor:      mutedIcon,
            title:          context.tr('profile.edit_profile'),
            semanticsLabel: context.tr('profile.edit_profile'),
            onTap:          () => context.push(AppRoutes.editProfile),
          ),
        SettingsTile(
          icon:           AppIcons.info,
          iconColor:      mutedIcon,
          title:          context.tr('profile.about'),
          semanticsLabel: context.tr('profile.about'),
          onTap:          () => context.push(AppRoutes.about),
        ),
        SettingsTile(
          icon:           AppIcons.help,
          iconColor:      mutedIcon,
          title:          context.tr('profile.help'),
          semanticsLabel: context.tr('profile.help'),
          onTap:          () => context.push(AppRoutes.help),
        ),

        const SizedBox(height: AppConstants.spacingSm),

        // A guest has no real account — sign-out / delete don't apply. Leaving
        // guest mode is done via the "create account" card at the top.
        if (!isGuest) ...[
          SignOutTile(
            onSignOut: isActionInProgress ? () {} : () => _confirmSignOut(context, ref),
            isEnabled: !isActionInProgress,
          ),

          const SizedBox(height: AppConstants.spacingXs),

          _DeleteAccountTile(
            isEnabled: !isActionInProgress,
            onTap:     () => _confirmDeleteAccount(context, ref),
          ),
        ],

        const SizedBox(height: AppConstants.spacingXl),

        Center(
          child: Text(
            '${context.tr('profile.version')} ${AppConstants.appVersion}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref, LanguageService languageService) {
    final current = ref.read(currentLocaleProvider).languageCode;

    showModalBottomSheet<void>(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => AppBottomSheet(
        title: context.tr('settings.language'),
        children: [
          SheetOption(
            label:      'Français',
            flag:       '🇫🇷',
            isSelected: current == 'fr',
            onTap: () {
              Navigator.of(sheetCtx).pop();
              languageService.changeToFrench();
            },
          ),
          SheetOption(
            label:      'English',
            flag:       '🇬🇧',
            isSelected: current == 'en',
            onTap: () {
              Navigator.of(sheetCtx).pop();
              languageService.changeToEnglish();
            },
          ),
          SheetOption(
            label:      'العربية',
            flag:       '🇩🇿',
            isSelected: current == 'ar',
            onTap: () {
              Navigator.of(sheetCtx).pop();
              languageService.changeToArabic();
            },
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet<void>(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => AppBottomSheet(
        title: context.tr('settings.theme'),
        children: [
          SheetOption(
            label:      context.tr('settings.system'),
            icon:       Icons.brightness_auto_rounded,
            isSelected: current == ThemeMode.system,
            onTap: () {
              Navigator.of(sheetCtx).pop();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
            },
          ),
          SheetOption(
            label:      context.tr('settings.light'),
            icon:       Icons.light_mode_rounded,
            isSelected: current == ThemeMode.light,
            onTap: () {
              Navigator.of(sheetCtx).pop();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
            },
          ),
          SheetOption(
            label:      context.tr('settings.dark'),
            icon:       Icons.dark_mode_rounded,
            isSelected: current == ThemeMode.dark,
            onTap: () {
              Navigator.of(sheetCtx).pop();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   Text(context.tr('auth.logout')),
        content: Text(context.tr('settings.logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child:     Text(context.tr('common.cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(settingsProvider.notifier).signOut();
            },
            child: Text(context.tr('auth.logout')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   Text(context.tr('settings.delete_account')),
        content: Text(context.tr('settings.delete_account_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child:     Text(context.tr('common.cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(settingsProvider.notifier).deleteAccount();
            },
            child: Text(context.tr('settings.delete_account_action')),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => context.tr('settings.system'),
      ThemeMode.light  => context.tr('settings.light'),
      ThemeMode.dark   => context.tr('settings.dark'),
    };
  }
}

// ── Delete-account row — error-tinted, the strongest destructive weight ──────

class _DeleteAccountTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool         isEnabled;

  const _DeleteAccountTile({
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final errorColor = isEnabled
        ? theme.colorScheme.error
        : theme.colorScheme.error.withValues(
            alpha: AppConstants.opacityDisabledColor,
          );

    return Semantics(
      label:   context.tr('settings.delete_account'),
      button:  true,
      enabled: isEnabled,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        child: InkWell(
          onTap:        isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: Container(
            height: AppConstants.tileHeight,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(
                alpha: isEnabled
                    ? (isDark
                        ? AppConstants.opacityDeleteTileFillDarkEn
                        : AppConstants.opacityDeleteFillLightEn)
                    : AppConstants.opacityDeleteFillDis,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusTile),
              border: Border.all(
                color: theme.colorScheme.error.withValues(
                  alpha: isEnabled
                      ? AppConstants.opacityIconBgAlt
                      : AppConstants.opacityDeleteBorderDis,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width:  AppConstants.iconContainerXl,
                  height: AppConstants.iconContainerXl,
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: AppConstants.opacityIconBg),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    AppIcons.deleteAccount,
                    color: errorColor,
                    size:  AppConstants.buttonIconSize,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingTileInner),
                Expanded(
                  child: Text(
                    context.tr('settings.delete_account'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: errorColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: errorColor.withValues(alpha: AppConstants.opacityChevron),
                  size:  AppConstants.buttonIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile-card loading skeleton ────────────────────────────────────────────

class _ProfileCardSkeleton extends StatelessWidget {
  const _ProfileCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: SkeletonBone(
        width:  double.infinity,
        height: AppConstants.profileCardSkeletonHeight,
        radius: AppConstants.radiusCircle,
      ),
    );
  }
}

// ── Biometric app-lock toggle ─────────────────────────────────────────────────
// Self-contained: reads/writes the pref via BiometricLockService, no global
// provider. Enabling first verifies device support + a live auth so the user
// can never switch on a lock they can't clear.
class _BiometricLockTile extends StatefulWidget {
  final Color iconColor;

  const _BiometricLockTile({required this.iconColor});

  @override
  State<_BiometricLockTile> createState() => _BiometricLockTileState();
}

class _BiometricLockTileState extends State<_BiometricLockTile> {
  final BiometricLockService _service = BiometricLockService();
  bool _enabled = false;
  bool _busy    = true;
  @override
  void initState() {
    super.initState();
    _service.isEnabled().then((v) {
      if (mounted) setState(() { _enabled = v; _busy = false; });
    });
  }

  Future<void> _toggle(bool want) async {
    final messenger   = ScaffoldMessenger.of(context);
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final reason      = context.tr('auth.biometric_reason');
    final unavailable = context.tr('settings.biometric_unavailable');
    if (want) {
      if (!await _service.canUse()) {
        messenger.showSnackBar(
          ErrorHandler.warningSnackBar(unavailable, isDark: isDark),
        );
        return;
      }
      if (!await _service.authenticate(reason)) return;
    }
    await _service.setEnabled(want);
    if (mounted) setState(() => _enabled = want);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon:           Icons.fingerprint,
      iconColor:      widget.iconColor,
      title:          context.tr('settings.biometric_lock'),
      semanticsLabel: context.tr('settings.biometric_lock'),
      onTap:          _busy ? () {} : () => _toggle(!_enabled),
      trailing: Switch(
        value:     _enabled,
        onChanged: _busy ? null : _toggle,
      ),
    );
  }
}
