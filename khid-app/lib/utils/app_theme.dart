// lib/utils/app_theme.dart
// [MANUAL FIX — labelSmall font size]:
//   Was fontSize: 10 in both dark and light textTheme.
//   Apple HIG minimum body text = 11pt; Android MDC minimum = 11sp.
//   Raised to 11dp in both themes to meet platform accessibility minimums.
//   All widgets using textTheme.labelSmall automatically benefit — no
//   call-site changes required.
//
// [AUTO FIX — opacity-baked tokens added]:
//   accentBorderSubtle      = Color(0x404F46E5)  — replaces accent.withOpacity(0.25)
//                             in _VerificationCard icon container border.
//   darkSecondaryTextMuted  = Color(0x997A6E96)  — replaces darkSecondaryText.withOpacity(0.6)
//   lightSecondaryTextMuted = Color(0x996B64A0)  — replaces lightSecondaryText.withOpacity(0.6)
//   Both muted tokens used in email_verification_screen change_account_hint text.
//
// [AUTO FIX — raw literal → token in theme definitions]:
//   textButtonTheme padding:
//     horizontal: 16 → AppConstants.paddingMd
//     vertical:   12 → AppConstants.paddingInputV
//   outlinedButtonTheme padding:
//     horizontal: 28 → AppConstants.paddingLg (24dp — nearest on-grid value)
//     vertical:   16 → AppConstants.paddingMd
//   appBarTheme titleTextStyle fontSize: 17 → AppConstants.fontSizeAppBar
//   snackBarTheme insetPadding: EdgeInsets.all(16) → EdgeInsets.all(AppConstants.paddingMd)
//   inputDecorationTheme contentPadding:
//     horizontal: 18 → AppConstants.inputPaddingH
//     vertical:   15 → AppConstants.inputPaddingV

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_enums.dart';
import 'constants.dart';

/// ============================================================
/// 🎨 KHIDMETI APP THEME — Midnight Indigo v2.0
/// ============================================================

class AppTheme {
  // ==========================================================
  // 🎨 CORE PALETTE — DARK THEME
  // ==========================================================

  static const Color darkBackground     = Color(0xFF080510);
  static const Color darkSurface        = Color(0xFF141028);
  static const Color darkSurfaceVariant = Color(0xFF1C1235);
  static const Color darkDeepBackground = Color(0xFF120820);
  static const Color darkText           = Color(0xFFF0EAFF);
  // Was 0xFF7A6E96 (3.8-4.3:1, below WCAG AA). Raised to 6.35:1 on darkSurface —
  // fixes all call sites at the token level.
  static const Color darkSecondaryText  = Color(0xFF9B91C0);
  static const Color darkTertiaryText   = Color(0xFF4A4260);
  static const Color darkAccent         = Color(0xFF4F46E5);
  static const Color darkBorder         = Color(0xFF221640);
  static const Color darkError          = Color(0xFFF87171);
  static const Color darkSuccess        = Color(0xFF34D399);
  static const Color darkWarning        = Color(0xFFFBBF24);

  // ==========================================================
  // 🎨 CORE PALETTE — LIGHT THEME
  // ==========================================================

  static const Color lightBackground    = Color(0xFFF8F7FF);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant= Color(0xFFF0EEFF);
  static const Color lightText          = Color(0xFF12041C);
  static const Color lightSecondaryText = Color(0xFF6B64A0);
  static const Color lightTertiaryText  = Color(0xFFA8A2D4);
  static const Color lightAccent        = Color(0xFF4F46E5);
  static const Color lightBorder        = Color(0xFFE0DBFF);
  static const Color lightError         = Color(0xFFDC2626);
  static const Color lightSuccess       = Color(0xFF16A34A);
  static const Color lightWarning       = Color(0xFFD97706);

  // ==========================================================
  // 🎨 OPACITY-BAKED TOKENS
  // ==========================================================

  static const Color darkBgAppBar          = Color(0xCC080510);
  static const Color darkErrorBorder       = Color(0xCCF87171);
  // Hints were 60% alpha of the old secondary (~2.2:1, near-invisible). Full-opacity
  // secondary text: still clearly dimmer than darkText (6.35 vs 15.8) but readable.
  static const Color darkHintText          = Color(0xFF9B91C0);
  static const Color darkBorderSubtle      = Color(0x33221640);
  static const Color darkAccentOverlay     = Color(0x334F46E5);
  static const Color darkAccentMid         = Color(0x804F46E5);
  static const Color darkSurfaceVariantMid = Color(0x801C1235);
  static const Color darkErrorSubtle       = Color(0x1AF87171);
  static const Color darkErrorMuted        = Color(0x99F87171);
  static const Color darkSurfaceHalf       = Color(0x80141028);
  static const Color lightBgAppBar         = Color(0xE6F8F7FF);
  static const Color lightErrorBorder      = Color(0xCCDC2626);
  // Was 70% alpha (~2.7:1). Full-opacity secondary text (5.31:1 on white).
  static const Color lightHintText         = Color(0xFF6B64A0);
  static const Color lightAccentChipOverlay= Color(0x264F46E5);
  static const Color lightAccentOverlay    = Color(0x334F46E5);
  static const Color lightAccentMid        = Color(0x804F46E5);
  static const Color lightErrorSubtle      = Color(0x1ADC2626);
  static const Color lightErrorMuted       = Color(0x99DC2626);

  // ==========================================================
  // 🎨 AUTH / SHEET OPACITY-BAKED TOKENS
  // ==========================================================

  static const Color darkAccentHalo       = Color(0x2E4F46E5);
  static const Color lightAccentHalo      = Color(0x124F46E5);
  static const Color accentDisabledFill   = Color(0x734F46E5);

  /// Accent icon container fill — replaces accent.withOpacity(0.12).
  /// Used in _VerificationCard icon container background (≈ 15% alpha).
  static const Color accentSelectedFill   = Color(0x264F46E5);

  /// Accent icon container border — replaces accent.withOpacity(0.25).
  /// Used in _VerificationCard icon container border (≈ 25% alpha = 0x40).
  static const Color accentBorderSubtle   = Color(0x404F46E5);

  static const Color sheetHandleDark      = Color(0x26FFFFFF);
  static const Color sheetHandleLight     = Color(0x1F000000);
  static const Color darkWarningSubtle    = Color(0x14FBBF24);
  static const Color lightWarningSubtle   = Color(0x14D97706);
  static const Color darkWarningBorder    = Color(0x4DFBBF24);
  static const Color lightWarningBorder   = Color(0x4DD97706);
  static const Color darkTileFill         = Color(0x0FFFFFFF);
  static const Color lightTileFill        = Color(0x0A000000);
  static const Color darkTileBorder       = Color(0x1AFFFFFF);
  static const Color lightTileBorder      = Color(0x14000000);
  static const Color darkSocialBorder     = Color(0x2EFFFFFF);
  static const Color darkBackButtonFill   = Color(0x14FFFFFF);
  static const Color lightBackButtonFill  = Color(0x0F000000);
  static const Color darkCheckboxBorder   = Color(0x40FFFFFF);
  static const Color lightCheckboxBorder  = Color(0x33000000);

  /// Muted dark secondary text. Was 60% alpha of the old secondary (~2.2:1 —
  /// unreadable). Now full-opacity secondary; de-emphasis comes from font size.
  static const Color darkSecondaryTextMuted  = Color(0xFF9B91C0);

  /// Muted light secondary text. Was 60% alpha (~2.4:1). Same fix as dark.
  static const Color lightSecondaryTextMuted = Color(0xFF6B64A0);

  // ==========================================================
  // 🎨 OVERLAY TOKENS
  // ==========================================================

  static const Color overlayScrim35 = Color(0x59000000);

  // ==========================================================
  // 🎨 PROFILE CARD TOKENS
  // ==========================================================

  static const Color profileCardBorder       = Color(0x33FFFFFF);
  static const Color profileCardBadgeFill    = Color(0x33FFFFFF);
  // Soft indigo lift under the profile hero card (0x24 ≈ 14%). Was 0x59 (35%)
  // which bloomed into a neon halo on the dark theme — softened to a subtle,
  // professional colored elevation.
  static const Color profileCardShadow       = Color(0x244F46E5);
  static const Color profileCardAvatarBorder = Color(0x80FFFFFF);
  static const Color profileCardRatingText   = Color(0xE6FFFFFF);

  // ==========================================================
  // 🎨 TOKENS — misc
  // ==========================================================

  static const Color whatsAppDarkSurface    = Color(0xFF1B2B1B);
  static const Color lightCardBorderOverlay = Color(0x12000000);
  static const Color darkCardBorderOverlay  = Color(0x12FFFFFF);

  static const List<Shadow> profileCardTextShadow = [
    Shadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // ==========================================================
  // 🎨 TEXT-SAFE ACCENT / STATUS TOKENS (contrast audit, Jul 2026)
  // ==========================================================
  // darkAccent (#4F46E5) is only ~3:1 as TEXT on dark surfaces — fine for
  // fills/borders, not for small text. These are the text-tier equivalents.

  /// Indigo-400 — accent used AS TEXT or icons on dark surfaces (5.9:1).
  static const Color darkAccentText  = Color(0xFF818CF8);

  /// Green-700 — online/success/accept TEXT on light surfaces (5.0:1 on white;
  /// onlineGreen #22C55E and acceptGreen #16A34A are 2.1-3.3:1 there).
  static const Color greenTextLight  = Color(0xFF15803D);

  /// Amber-700 — warning/rating TEXT on light surfaces (5.0:1 on white;
  /// warningAmber #FBBF24 is 1.66:1 there).
  static const Color amberTextLight  = Color(0xFFB45309);

  /// WhatsApp brand deep teal — WhatsApp TEXT/icons on light surfaces (7.7:1;
  /// whatsAppGreen #25D366 is 1.97:1 on white).
  static const Color whatsAppDeep    = Color(0xFF075E54);

  static const Color overlayDark = Color(0x73000000);

  // ==========================================================
  // 🎨 MODAL SHADOW TOKENS
  // ==========================================================

  static const BoxShadow modalShadowDark = BoxShadow(
    color:      Color(0x66000000),
    blurRadius: 24,
    offset:     Offset(0, -4),
  );

  static const BoxShadow modalShadowLight = BoxShadow(
    color:      Color(0x2E000000),
    blurRadius: 24,
    offset:     Offset(0, -4),
  );

  // ==========================================================
  // 🎨 SHIMMER / SKELETON TOKENS
  // ==========================================================

  static const Color shimmerBaseDark       = Color(0x12F0EAFF);
  static const Color shimmerHighlightDark  = Color(0x26F0EAFF);
  static const Color shimmerBaseLight      = Color(0x0D12041C);
  static const Color shimmerHighlightLight = Color(0x1A12041C);

  // ==========================================================
  // 🎨 WHATSAPP TOKENS
  // ==========================================================

  static const Color whatsAppGreen = Color(0xFF25D366);
  static const Color whatsAppDark  = Color(0xFF128C7E);

  // ==========================================================
  // 🎨 FEATURE / KEPT COLOURS
  // ==========================================================

  static const Color aiPrimary          = Color(0xFF6C47FF);
  static const Color onlineGreen        = Color(0xFF22C55E);
  static const Color recordingRed       = Color(0xFFF44336);
  static const Color signOutRed         = Color(0xFFEF4444);
  static const Color priorityNormalDark = Color(0xFF34D399);
  static const Color warningAmber       = Color(0xFFFBBF24);
  /// "You are here" map dot — platform-convention blue (Google/Apple Maps).
  static const Color mapLocationBlue    = Color(0xFF06B6D4);
  static const Color acceptGreen        = Color(0xFF16A34A);
  static const Color darkAuthHeroTop    = Color(0xFF120820);

  // ==========================================================
  // 🎨 STATUS COLOUR TOKENS
  // ==========================================================

  // Was 0xCC4F46E5 (~2.6:1 as badge text on dark cards). Text-safe indigo-400.
  static const Color statusOpenDark  = Color(0xFF818CF8);
  static const Color statusOpenLight = Color(0xCC4F46E5);

  static const Color statusAcceptedDark  = Color(0xFF60A5FA);
  static const Color statusAcceptedLight = Color(0xFF2563EB);

  static const Color statusInProgressDark  = Color(0xFFA78BFA);
  static const Color statusInProgressLight = Color(0xFF7C3AED);

  static const Color statusCancelledDark  = Color(0xFFF87171);
  static const Color statusCancelledLight = Color(0xFFDC2626);

  // ==========================================================
  // 🎨 DISABLED STATE
  // ==========================================================

  static const Color disabledFill   = Color(0x1A9E9E9E);
  static const Color disabledBorder = Color(0x339E9E9E);

  // ==========================================================
  // 🌑 DARK THEME
  // ==========================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness:   Brightness.dark,
      colorScheme: const ColorScheme.dark(
        brightness:              Brightness.dark,
        primary:                 darkAccent,
        onPrimary:               Colors.white,
        secondary:               darkAccent,
        onSecondary:             Colors.white,
        surface:                 darkSurface,
        onSurface:               darkText,
        onSurfaceVariant:        darkSecondaryText,
        surfaceContainerLowest:  darkBackground,
        error:                   darkError,
        onError:                 Colors.black,
        errorContainer:          Color(0xFF3B1524),
        onErrorContainer:        darkError,
        surfaceContainerHighest: darkSurfaceVariant,
        outline:                 darkBorder,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        elevation:   0,
        color:       darkSurface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          side: const BorderSide(color: darkBorder, width: 0.5),
        ),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: darkBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: darkBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: darkErrorBorder, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: darkError, width: 1.5),
        ),
        labelStyle:         const TextStyle(color: darkSecondaryText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        floatingLabelStyle: const TextStyle(color: darkAccentText, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        hintStyle:          const TextStyle(color: darkHintText, fontFamily: 'Inter'),
        contentPadding:     const EdgeInsets.symmetric(
          horizontal: AppConstants.inputPaddingH,
          vertical:   AppConstants.inputPaddingV,
        ),
        prefixIconColor:    darkSecondaryText,
        suffixIconColor:    darkSecondaryText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.white,
          elevation:       0,
          minimumSize:     const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
          textStyle: const TextStyle(fontSize: AppConstants.buttonFontSize, fontWeight: FontWeight.w700, letterSpacing: -0.2, fontFamily: 'Inter'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkAccentText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical:   AppConstants.paddingInputV,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: darkBorderSubtle, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLg,
            vertical:   AppConstants.paddingMd,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation:              0,
        scrolledUnderElevation: 0,
        backgroundColor:        darkBgAppBar,
        foregroundColor:        darkText,
        centerTitle:            true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color:         darkText,
          fontSize:      AppConstants.fontSizeAppBar,
          fontWeight:    FontWeight.w600,
          fontFamily:    'Inter',
          letterSpacing: -0.3,
        ),
        iconTheme:        IconThemeData(color: darkAccentText, size: 24),
        actionsIconTheme: IconThemeData(color: darkText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      darkSurface,
        selectedItemColor:    darkAccentText,
        unselectedItemColor:  darkSecondaryText,
        type:                 BottomNavigationBarType.fixed,
        elevation:            0,
        selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Inter'),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12, fontFamily: 'Inter'),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: const TextStyle(color: darkText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: const BorderSide(color: darkBorderSubtle),
        ),
        behavior:     SnackBarBehavior.floating,
        elevation:    0,
        insetPadding: const EdgeInsets.all(AppConstants.paddingMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXxl),
          side: const BorderSide(color: darkBorderSubtle, width: 0.5),
        ),
        titleTextStyle:   const TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
        contentTextStyle: const TextStyle(color: darkSecondaryText, fontSize: 15, fontFamily: 'Inter'),
      ),
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -1.5),
        displayMedium:  TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -1),
        displaySmall:   TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -0.5),
        headlineLarge:  TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter', letterSpacing: -0.6),
        headlineSmall:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter', letterSpacing: -0.3),
        titleLarge:     TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter'),
        titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter'),
        titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkSecondaryText, fontFamily: 'Inter'),
        bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: darkText, fontFamily: 'Inter', height: 1.6),
        bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkText, fontFamily: 'Inter', height: 1.6),
        bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: darkSecondaryText, fontFamily: 'Inter', height: 1.5),
        labelLarge:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText, fontFamily: 'Inter'),
        labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkSecondaryText, fontFamily: 'Inter'),
        // [MANUAL FIX]: was fontSize: 10 — below Apple HIG (11pt) and Android
        // MDC (11sp) minimums. Raised to 11dp to meet both platform standards.
        labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: darkText, fontFamily: 'Inter', letterSpacing: 0.10),
      ),
      dividerTheme: const DividerThemeData(color: darkBorderSubtle, thickness: 1, space: 24),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXxl))),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor:     darkSurfaceVariant,
        selectedColor:       darkAccentOverlay,
        labelStyle:          const TextStyle(color: darkText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        secondaryLabelStyle: const TextStyle(color: darkAccentText, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.chipPaddingH, vertical: AppConstants.chipPaddingV),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          side: const BorderSide(color: darkBorderSubtle),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? darkAccent : darkSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected)
              ? darkAccentMid
              : darkSurfaceVariantMid,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor:   darkAccent,
        inactiveTrackColor: darkSurfaceVariant,
        thumbColor:         darkAccent,
        overlayColor:       darkAccentOverlay,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:              darkAccent,
        circularTrackColor: darkSurfaceVariant,
        linearTrackColor:   darkSurfaceVariant,
      ),
    );
  }

  // ==========================================================
  // ☀️ LIGHT THEME
  // ==========================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness:   Brightness.light,
      colorScheme: const ColorScheme.light(
        brightness:              Brightness.light,
        primary:                 lightAccent,
        onPrimary:               Colors.white,
        secondary:               lightAccent,
        onSecondary:             Colors.white,
        surface:                 lightSurface,
        onSurface:               lightText,
        onSurfaceVariant:        lightSecondaryText,
        surfaceContainerLowest:  lightBackground,
        error:                   lightError,
        onError:                 Colors.white,
        errorContainer:          Color(0xFFFEE2E2),
        onErrorContainer:        Color(0xFF991B1B),
        surfaceContainerHighest: lightSurfaceVariant,
        outline:                 lightBorder,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardTheme: CardThemeData(
        elevation:   0,
        color:       lightSurface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: lightBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: lightBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: lightAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: lightErrorBorder, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
          borderSide: const BorderSide(color: lightError, width: 1.5),
        ),
        labelStyle:         const TextStyle(color: lightSecondaryText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        floatingLabelStyle: const TextStyle(color: lightAccent, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        hintStyle:          const TextStyle(color: lightHintText, fontFamily: 'Inter'),
        contentPadding:     const EdgeInsets.symmetric(
          horizontal: AppConstants.inputPaddingH,
          vertical:   AppConstants.inputPaddingV,
        ),
        prefixIconColor:    lightSecondaryText,
        suffixIconColor:    lightSecondaryText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          elevation:       0,
          minimumSize:     const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
          textStyle: const TextStyle(fontSize: AppConstants.buttonFontSize, fontWeight: FontWeight.w700, letterSpacing: -0.2, fontFamily: 'Inter'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical:   AppConstants.paddingInputV,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          side: const BorderSide(color: lightBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLg,
            vertical:   AppConstants.paddingMd,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation:              0,
        scrolledUnderElevation: 0,
        backgroundColor:        lightBgAppBar,
        foregroundColor:        lightText,
        centerTitle:            true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color:         lightText,
          fontSize:      AppConstants.fontSizeAppBar,
          fontWeight:    FontWeight.w600,
          fontFamily:    'Inter',
          letterSpacing: -0.3,
        ),
        iconTheme:        IconThemeData(color: lightAccent, size: 24),
        actionsIconTheme: IconThemeData(color: lightText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      lightSurface,
        selectedItemColor:    lightAccent,
        unselectedItemColor:  lightSecondaryText,
        type:                 BottomNavigationBarType.fixed,
        elevation:            0,
        selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Inter'),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12, fontFamily: 'Inter'),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightText,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: const BorderSide(color: lightBorder),
        ),
        behavior:     SnackBarBehavior.floating,
        elevation:    4,
        insetPadding: const EdgeInsets.all(AppConstants.paddingMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXxl),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
        titleTextStyle:   const TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
        contentTextStyle: const TextStyle(color: lightSecondaryText, fontSize: 15, fontFamily: 'Inter'),
      ),
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -1.5),
        displayMedium:  TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -1),
        displaySmall:   TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -0.5),
        headlineLarge:  TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter', letterSpacing: -0.6),
        headlineSmall:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter', letterSpacing: -0.3),
        titleLarge:     TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter'),
        titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter'),
        titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lightSecondaryText, fontFamily: 'Inter'),
        bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: lightText, fontFamily: 'Inter', height: 1.6),
        bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: lightText, fontFamily: 'Inter', height: 1.6),
        bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: lightSecondaryText, fontFamily: 'Inter', height: 1.5),
        labelLarge:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lightText, fontFamily: 'Inter'),
        labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: lightSecondaryText, fontFamily: 'Inter'),
        // [MANUAL FIX]: was fontSize: 10 — below Apple HIG (11pt) and Android
        // MDC (11sp) minimums. Raised to 11dp to meet both platform standards.
        labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lightText, fontFamily: 'Inter', letterSpacing: 0.10),
      ),
      dividerTheme:     const DividerThemeData(color: lightBorder, thickness: 1, space: 24),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXxl))),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor:     lightSurfaceVariant,
        selectedColor:       lightAccentChipOverlay,
        labelStyle:          const TextStyle(color: lightText, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        secondaryLabelStyle: const TextStyle(color: lightAccent, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.chipPaddingH, vertical: AppConstants.chipPaddingV),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? lightAccent : lightSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (s) => s.contains(WidgetState.selected) ? lightAccentMid : lightBorder,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor:   lightAccent,
        inactiveTrackColor: lightBorder,
        thumbColor:         lightAccent,
        overlayColor:       lightAccentOverlay,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:              lightAccent,
        circularTrackColor: lightSurfaceVariant,
        linearTrackColor:   lightSurfaceVariant,
      ),
    );
  }

  // ==========================================================
  // 🎨 HELPER METHODS
  // ==========================================================

  static Color getStatusColor(ServiceStatus status, bool isDark) {
    switch (status) {
      case ServiceStatus.open:
      case ServiceStatus.pending:
        return isDark ? statusOpenDark : statusOpenLight;
      case ServiceStatus.awaitingSelection:
        // lightWarning (#D97706) is 3.19:1 on white — badge text needs the
        // amber-700 text tier in light mode.
        return isDark ? darkWarning : amberTextLight;
      case ServiceStatus.bidSelected:
      case ServiceStatus.accepted:
        return isDark ? statusAcceptedDark : statusAcceptedLight;
      case ServiceStatus.inProgress:
        return isDark ? statusInProgressDark : statusInProgressLight;
      case ServiceStatus.completed:
        // lightSuccess (#16A34A) is 3.30:1 on white — green-700 text tier.
        return isDark ? darkSuccess : greenTextLight;
      case ServiceStatus.cancelled:
      case ServiceStatus.declined:
      case ServiceStatus.expired:
        return isDark ? statusCancelledDark : statusCancelledLight;
    }
  }

  static IconData getProfessionIcon(String serviceType) {
    const map = <String, IconData>{
      'plumber':          Icons.plumbing_rounded,
      'electrician':      Icons.electrical_services_rounded,
      'cleaner':          Icons.cleaning_services_rounded,
      'painter':          Icons.format_paint_rounded,
      'carpenter':        Icons.carpenter_rounded,
      'mason':            Icons.domain_rounded,
      'ac_repair':        Icons.air_rounded,
      'gardener':         Icons.grass_rounded,
      'appliance_repair': Icons.kitchen_rounded,
    };
    return map[serviceType] ?? Icons.work_outline_rounded;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MOD PASS: Semantic Text Style Helpers
  // ──────────────────────────────────────────────────────────────────────────
  // Reduce copyWith() calls that allocate new TextStyle objects on every build.

  /// Muted body text (bodySmall color, slightly transparent) — used for
  /// secondary descriptions, subtitles, disabled state text.
  static TextStyle bodyMuted(bool isDark) => AppConstants.bodyMuted.copyWith(
        // Full opacity: 0.7 alpha dropped both modes below 4.5:1 AA.
        color: isDark ? darkSecondaryText : lightSecondaryText,
      );

  /// Card title text (titleSmall bold 700) — used in CardContainer headers,
  /// BidCard, JobCard, RequestCard titles. Pre-defined to avoid repeated
  /// copyWith(fontWeight: w700) across 20+ widgets.
  static TextStyle titleCardSmall(bool isDark) =>
      AppConstants.titleCardSmall.copyWith(
        color: isDark ? darkText : lightText,
      );

  /// Label text (small, bold, uppercased) — field labels, badges, tags.
  static TextStyle labelSmallBold(bool isDark) =>
      AppConstants.labelSmallBold.copyWith(
        color: isDark ? darkSecondaryText : lightSecondaryText,
      );
}
