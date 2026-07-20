// lib/screens/home/widgets/home_cta_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/require_auth.dart';

// ============================================================================
// HOME CTA BUTTON — Design C: square icon + title + subtitle + pill badge
// ============================================================================

class HomeCtaButton extends ConsumerStatefulWidget {
  const HomeCtaButton({super.key});

  @override
  ConsumerState<HomeCtaButton> createState() => _HomeCtaButtonState();
}

class _HomeCtaButtonState extends ConsumerState<HomeCtaButton> {
  bool _pressed = false;

  Future<void> _onTap(BuildContext context) async {
    HapticFeedback.mediumImpact();
    if (!await requireAuth(context, ref)) return;
    if (!context.mounted) return;
    context.push(AppRoutes.serviceRequest, extra: {'isEmergency': false});
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppTheme.darkAccent  : AppTheme.lightAccent;
    final border  = isDark ? AppTheme.darkBorder   : AppTheme.lightBorder;
    final text    = isDark ? AppTheme.darkText      : AppTheme.lightText;
    final subtext = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Semantics(
      button: true,
      label:  context.tr('home.cta_schedule'),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          _onTap(context);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale:    _pressed ? 0.974 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            height: AppConstants.buttonHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withValues(alpha: 0.60)
                  : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border:       Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppConstants.spacingChipGap),

                // Square icon container
                Container(
                  width:  AppConstants.iconContainerXl,
                  height: AppConstants.iconContainerXl,
                  decoration: BoxDecoration(
                    color:        accent.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: accent.withValues(alpha: isDark ? 0.25 : 0.20),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    AppIcons.requests,
                    color: accent,
                    size:  20,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingChipGap),

                // Title + subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home.cta_schedule'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color:         text,
                              fontWeight:    FontWeight.w700,
                              letterSpacing: -0.3,
                              height:        1.1,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppConstants.spacingXxs),
                      Text(
                        context.tr('home.cta_schedule_sub'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: subtext,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Pill badge
                Container(
                  margin: const EdgeInsets.only(
                      right: AppConstants.spacingChipGap),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical:   AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
                  ),
                  child: Text(
                    context.tr('home.cta_new'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight:    FontWeight.w700,
                          color:         Theme.of(context).colorScheme.onPrimary,
                          letterSpacing: -0.2,
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
}
