// lib/screens/home/widgets/home_quick_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_controller.dart';
import '../../../providers/user_role_provider.dart';
import '../../../providers/worker_home_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'home_categories_sheet.dart';
import 'home_cta_button.dart';
import 'home_service_grid.dart';

// ============================================================================
// HOME QUICK ACTIONS
// ============================================================================

class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeFilter = ref.watch(
      homeControllerProvider.select((s) => s.activeServiceFilter),
    );

    // Both watches unconditional — a watch inside a ternary breaks Riverpod's
    // stable-subscription rule (stale listeners). The extra subscription is
    // cheap for clients.
    final isWorker = ref.watch(cachedUserRoleProvider) == UserRole.worker;
    final workerOnlineRaw = ref.watch(
      workerHomeControllerProvider.select((s) => s.isOnline),
    );
    final workerIsOnline = isWorker && workerOnlineRaw;

    return Column(
      mainAxisSize:       MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Services section ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLg,
            AppConstants.paddingLg,
            AppConstants.paddingLg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label + "Voir tout"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('home.our_services'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                  ),
                  Semantics(
                    button: true,
                    label:  context.tr('home.see_all'),
                    child: GestureDetector(
                      onTap: () => HomeCategoriesSheet.show(
                        context,
                        (filter) {
                          ref
                              .read(homeControllerProvider.notifier)
                              .toggleServiceFilter(filter);
                          if (filter != null) {
                            ref
                                .read(homeControllerProvider.notifier)
                                .enterMapFullscreen();
                          }
                        },
                      ),
                      child: SizedBox(
                        height: AppConstants.buttonHeightMd,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            context.tr('home.see_all'),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color:      isDark
                                      ? AppTheme.darkText
                                      : AppTheme.lightAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Scrollable service chips — "Vous" chip prepended for workers
              HomeServiceGrid(
                activeFilter:    activeFilter,
                isWorker:        isWorker,
                workerIsOnline:  workerIsOnline,
                onFilterChanged: (filter) {
                  ref
                      .read(homeControllerProvider.notifier)
                      .toggleServiceFilter(filter);
                  if (filter != null) {
                    ref
                        .read(homeControllerProvider.notifier)
                        .enterMapFullscreen();
                  }
                },
              ),
            ],
          ),
        ),

        // ── Visual separator ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLg,
            vertical:   AppConstants.paddingLg,
          ),
          child: Divider(
            height:    1,
            thickness: 1,
            color: isDark
                ? AppTheme.darkBorder.withValues(alpha: 0.35)
                : AppTheme.lightBorder,
          ),
        ),

        // ── CTA button ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLg,
            0,
            AppConstants.paddingLg,
            AppConstants.paddingSm,
          ),
          child: const HomeCtaButton(),
        ),
      ],
    );
  }
}
