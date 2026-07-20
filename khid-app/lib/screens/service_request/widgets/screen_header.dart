// lib/screens/service_request/widgets/screen_header.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/back_button.dart';
import 'request_form_stepper.dart';

// ============================================================================
// SERVICE REQUEST SCREEN HEADER
// Fixed header with back button, title, emergency badge, tab bar, stepper.
// ============================================================================

class ServiceRequestScreenHeader extends StatelessWidget {
  final bool          isDark;
  final Color         accent;
  final bool          isEmergency;
  final int           currentStep;
  final TabController tabController;
  final bool          showStepper;

  const ServiceRequestScreenHeader({
    super.key,
    required this.isDark,
    required this.accent,
    required this.isEmergency,
    required this.currentStep,
    required this.tabController,
    required this.showStepper,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title row ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppConstants.paddingMd,
                AppConstants.paddingMd,
                AppConstants.paddingMd,
                0,
              ),
              child: Row(
                children: [
                  // withBorder: true matches the original design of this
                  // specific header. appBack pops when there is history and
                  // falls back to home when the screen was reached with go()
                  // (deep link) — never a dead button.
                  AppBackButton(
                    isDark:    isDark,
                    withBorder: true,
                    onPressed: () => appBack(context),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('requests.title'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (isEmergency)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width:  6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.tr('request_form.emergency_mode'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:      accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppConstants.paddingMd,
              ),
              child: TabBar(
                controller:           tabController,
                indicatorColor:       accent,
                indicatorWeight:      2,
                indicatorSize:        TabBarIndicatorSize.tab,
                dividerColor:         Colors.transparent,
                labelColor:           isDark ? AppTheme.darkText : AppTheme.lightText,
                unselectedLabelColor: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
                labelStyle: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.labelMedium,
                tabs: [
                  Tab(text: context.tr('requests.new_request')),
                  Tab(text: context.tr('requests.my_requests')),
                ],
              ),
            ),

            // ── Stepper (form tab only) ────────────────────────────────
            if (showStepper)
              RequestFormStepper(
                currentStep: currentStep,
                accent:      accent,
                isDark:      isDark,
              ),
          ],
        ),
      ),
    );
  }
}
