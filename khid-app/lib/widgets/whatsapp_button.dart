// lib/widgets/whatsapp_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/app_social_assets.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WhatsAppIcon
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the official WhatsApp SVG logo.
///
/// Mirrors the pattern used by every other social icon in the project:
/// [SvgPicture.asset] from [AppSocialAssets.whatsapp].
///
/// Colour rules (identical to Apple/Facebook/Google siblings):
///   • Full-colour SVG  → set [colorFilter] to null (default). The SVG
///     already carries WhatsApp's brand green; no tinting is needed.
///   • Monochrome SVG   → pass a [colorFilter] to enforce brand colour:
///
///       WhatsAppIcon(
///         colorFilter: ColorFilter.mode(
///           AppTheme.whatsAppGreen, BlendMode.srcIn,
///         ),
///       )
///
/// Falls back to [_WhatsAppFallback] when the SVG asset is missing.
class WhatsAppIcon extends StatelessWidget {
  final double size;

  /// Optional tint — leave null for full-colour SVGs.
  final ColorFilter? colorFilter;

  const WhatsAppIcon({
    super.key,
    this.size = 24,
    this.colorFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppSocialAssets.whatsapp,
      width: size,
      height: size,
      colorFilter: colorFilter,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _WhatsAppFallback(size: size),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback (shown while SVG loads or if asset is missing)
// ─────────────────────────────────────────────────────────────────────────────

/// Pure-Flutter fallback — visible only when the SVG asset has not yet been
/// added to the project.
class _WhatsAppFallback extends StatelessWidget {
  final double size;
  const _WhatsAppFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.whatsAppGreen,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Icon(
          Icons.phone_rounded,
          color: Colors.white,
          size: size * 0.60,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Button styles (unchanged API — callers keep working with no edits)
// ─────────────────────────────────────────────────────────────────────────────

/// [ButtonStyle] for an outlined WhatsApp CTA button.
ButtonStyle whatsAppOutlinedStyle({required bool isDark}) {
  return OutlinedButton.styleFrom(
    backgroundColor: isDark ? AppTheme.whatsAppDarkSurface : Colors.white,
    foregroundColor: AppTheme.whatsAppGreen,
    side: BorderSide(color: AppTheme.whatsAppGreen.withValues(alpha: 0.6), width: 1.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );
}

/// [ButtonStyle] for a filled WhatsApp CTA button.
ButtonStyle whatsAppFilledStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppTheme.whatsAppDark,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
