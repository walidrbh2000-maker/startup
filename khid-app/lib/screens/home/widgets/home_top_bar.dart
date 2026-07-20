// lib/screens/home/widgets/home_top_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/home_controller.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/require_auth.dart';
import '../../../widgets/app_container.dart';
import '../../../widgets/pin_promo_banner.dart';
import '../../../widgets/wordmark.dart';
import 'home_hero_carousel.dart';
import 'location_address_display.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAddress = ref.watch(
      homeControllerProvider.select((s) => s.userAddress),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top:    AppConstants.heroPaddingTop,
        start:  AppConstants.heroPaddingH,
        end:    AppConstants.heroPaddingH,
        bottom: AppConstants.heroPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Wordmark row ───────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppWordmark(),
              const Spacer(),
              Semantics(
                label:  context.tr('profile.notifications'),
                button: true,
                child: GestureDetector(
                  onTap: () async {
                    if (!await requireAuth(context, ref)) return;
                    if (context.mounted) {
                      context.push(AppRoutes.notificationsInbox);
                    }
                  },
                  child: AppIconButton(
                    icon:   AppIcons.notifications,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // One-time PIN recommendation (7-day-old accounts without a PIN).
          const PinPromoBanner(),

          // ── Hero carousel ──────────────────────────────────────────────────
          // Replaces the static hero question: three auto-scrolling cards that
          // glide left in an endless loop (offers / services / trust).
          MediaQuery.disableAnimationsOf(context)
              ? const HomeHeroCarousel()
              : const HomeHeroCarousel()
                  .animate()
                  .fade(duration: 800.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOut),

          const SizedBox(height: AppConstants.spacingSm),

          // ── Location row ──────────────────────────────────────────────────
          MediaQuery.disableAnimationsOf(context)
              ? LocationAddressDisplay(address: userAddress)
              : LocationAddressDisplay(address: userAddress)
                  .animate()
                  .fade(delay: 700.ms, duration: 800.ms)
                  .slideY(begin: 0.2, end: 0, delay: 700.ms, duration: 800.ms),
        ],
      ),
    );
  }
}
