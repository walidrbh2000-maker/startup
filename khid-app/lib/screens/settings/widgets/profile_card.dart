// lib/screens/settings/widgets/profile_card.dart
//
// The settings hero: gradient card with avatar, name, profession badge, and
// rating. Shares the profileCard* tokens (border/shadow/badge/rating) with the
// worker_profile hero — the one approved gradient surface in the app.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/app_user_avatar.dart';
import '../../../providers/settings_provider.dart';

class ProfileCard extends StatelessWidget {
  final SettingsState state;

  const ProfileCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      label:     context.tr('settings.profile_section'),
      container: true,
      child: Container(
        decoration: BoxDecoration(
          // Subtle diagonal sheen (lighter top-left → base → slightly deeper
          // bottom-right) gives the hero card depth without a flat, cheap fill.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [
              Color.lerp(accent, Colors.white, 0.10)!,
              accent,
              Color.lerp(accent, Colors.black, 0.12)!,
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
          border: Border.all(
            color: AppTheme.profileCardBorder,
            width: AppConstants.cardBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              // Baked from the accent @ ~14% (safe while light/dark accents match).
              color:      AppTheme.profileCardShadow,
              blurRadius: 20,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMdLg,
          vertical:   AppConstants.spacingMdLg,
        ),
        child: Row(
          children: [
            AppUserAvatar(
              imageUrl: state.profileImageUrl,
              name:     state.userName ?? '',
              radius:      24,
              borderColor: AppTheme.profileCardAvatarBorder,
              borderWidth: 2.5,
            ),

            const SizedBox(width: AppConstants.paddingMd),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.userName ?? '',
                    style: TextStyle(
                      color:         Colors.white,
                      fontSize:      AppConstants.fontSizeXl,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: -0.3,
                      shadows:       AppTheme.profileCardTextShadow,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (state.isWorkerAccount &&
                      state.professionLabel != null &&
                      state.professionLabel!.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.badgePaddingH,
                        vertical:   AppConstants.badgePaddingV,
                      ),
                      decoration: BoxDecoration(
                        color:        AppTheme.profileCardBadgeFill,
                        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                      ),
                      child: Text(
                        context.tr('services.${state.professionLabel}'),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   AppConstants.fontSizeXxs,
                          fontWeight: FontWeight.w600,
                          shadows:    AppTheme.profileCardTextShadow,
                        ),
                      ),
                    ),
                  ],

                  if (state.isWorkerAccount &&
                      state.workerAverageRating != null &&
                      state.workerRatingCount != null &&
                      state.workerRatingCount! > 0) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '★ ${state.workerAverageRating!.toStringAsFixed(1)}'
                      ' (${state.workerRatingCount})',
                      style: const TextStyle(
                        color:      AppTheme.profileCardRatingText,
                        fontSize:   AppConstants.fontSizeXxs,
                        fontWeight: FontWeight.w600,
                        shadows:    AppTheme.profileCardTextShadow,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppConstants.spacingSm),
          ],
        ),
      ),
    );
  }
}
