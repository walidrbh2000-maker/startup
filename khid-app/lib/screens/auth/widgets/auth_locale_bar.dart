// lib/screens/auth/widgets/auth_locale_bar.dart
//
// Login-screen locale controls — a single segmented "glass" pill with two
// segments: language (flag + code) and theme (sun/moon/auto). Matches the
// pattern used by international apps: locale + theme live only on the auth
// entry screen, top-right.
//

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/core_providers.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/language_service.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_chrome.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Language options
// ─────────────────────────────────────────────────────────────────────────────

class _LangOption {
  final String code;
  final String flag;
  final String label;

  const _LangOption({
    required this.code,
    required this.flag,
    required this.label,
  });
}

const List<_LangOption> _kLangs = [
  _LangOption(code: 'fr', flag: '🇫🇷', label: 'Français'),
  _LangOption(code: 'ar', flag: '🇩🇿', label: 'العربية'),
  _LangOption(code: 'en', flag: '🇬🇧', label: 'English'),
];

String _flagForCode(String code) => _kLangs
    .firstWhere((l) => l.code == code, orElse: () => _kLangs.first)
    .flag;

// ─────────────────────────────────────────────────────────────────────────────
// Segmented locale bar
// ─────────────────────────────────────────────────────────────────────────────

class AuthLocaleBar extends ConsumerWidget {
  const AuthLocaleBar({super.key});

  ThemeMode _nextMode(ThemeMode current) {
    switch (current) {
      case ThemeMode.system: return ThemeMode.light;
      case ThemeMode.light:  return ThemeMode.dark;
      case ThemeMode.dark:   return ThemeMode.system;
    }
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return Icons.brightness_auto_rounded;
      case ThemeMode.light:  return Icons.light_mode_rounded;
      case ThemeMode.dark:   return Icons.dark_mode_rounded;
    }
  }

  String _themeLabelKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'settings.system';
      case ThemeMode.light:  return 'settings.light';
      case ThemeMode.dark:   return 'settings.dark';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(currentLanguageCodeProvider);
    final mode     = ref.watch(themeModeProvider);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final accent   = isDark ? AppTheme.darkAccentText : AppTheme.lightAccent;

    final divider = Container(
      width:  1,
      height: 20,
      color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
          .withValues(alpha: 0.6),
    );

    return DecoratedBox(
      // Soft lift — outside the clip so it isn't blurred away.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: AppConstants.buttonHeightMd,
            decoration: BoxDecoration(
              // Frosted surface — translucent so the gradient reads through.
              color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
                  .withValues(alpha: isDark ? 0.55 : 0.72),
              border: Border.all(
                color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                    .withValues(alpha: 0.8),
                width: AppConstants.borderWidthDefault,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Language segment ─────────────────────────────────────────
                Semantics(
                  button: true,
                  label:  '${context.tr("settings.language")}: $langCode',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showLanguageSheet(context, ref, langCode, isDark);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMd,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_flagForCode(langCode),
                              style: const TextStyle(
                                  fontSize: AppConstants.iconSizeSm)),
                          const SizedBox(width: AppConstants.spacingXs),
                          Text(
                            langCode.toUpperCase(),
                            style: TextStyle(
                              fontSize:      AppConstants.fontSizeSm,
                              fontWeight:    FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppTheme.darkText
                                  : AppTheme.lightText,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingXxs),
                          Icon(
                            AppIcons.arrowDown,
                            size:  AppConstants.iconSizeXs,
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                divider,

                // ── Theme segment ────────────────────────────────────────────
                Semantics(
                  button: true,
                  label:  context.tr(_themeLabelKey(mode)),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(_nextMode(mode));
                    },
                    child: SizedBox(
                      width:  AppConstants.buttonHeightMd,
                      height: AppConstants.buttonHeightMd,
                      child: AnimatedSwitcher(
                        duration: AppConstants.animDurationMicro,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Icon(
                          _iconFor(mode),
                          key:   ValueKey(mode),
                          size:  AppConstants.iconSizeSm,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(
    BuildContext context,
    WidgetRef    ref,
    String       current,
    bool         isDark,
  ) {
    showModalBottomSheet<void>(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(
        current: current,
        isDark:  isDark,
        onSelect: (code) async {
          Navigator.pop(context);
          await ref.read(languageServiceProvider).changeLanguage(code);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language selection sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  final String               current;
  final bool                 isDark;
  final ValueChanged<String> onSelect;

  const _LanguageSheet({
    required this.current,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.paddingMd,
        AppConstants.paddingLg,
        MediaQuery.of(context).padding.bottom + AppConstants.paddingLg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHandle(isDark: isDark),
          const SizedBox(height: AppConstants.spacingLg),
          Semantics(
            header: true,
            child: Text(
              context.tr('settings.language'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          ...(_kLangs.map((lang) {
            final isSelected = lang.code == current;
            return Semantics(
              button:   true,
              selected: isSelected,
              label:    lang.label,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(lang.code);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
                  height: AppConstants.tileHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMd,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentSelectedFill
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? accent
                          : (isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder),
                      width: isSelected
                          ? AppConstants.borderWidthSelected
                          : AppConstants.borderWidthDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang.flag,
                          style: const TextStyle(
                              fontSize: AppConstants.iconSizeSm)),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Text(
                          lang.label,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeMd,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isDark
                                ? AppTheme.darkText
                                : AppTheme.lightText,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: accent, size: AppConstants.iconSizeSm),
                    ],
                  ),
                ),
              ),
            );
          })),
        ],
      ),
    );
  }
}
