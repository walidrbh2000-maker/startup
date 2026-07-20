// lib/screens/subscription/widgets/subscription_locked_view.dart
//
// Shown in place of the worker features when the visibility subscription is
// inactive. A lock empty-state whose CTA opens the subscription screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/feature_empty_state.dart';

class SubscriptionLockedView extends StatelessWidget {
  const SubscriptionLockedView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return FeatureEmptyState(
      isDark:   isDark,
      icon:     Icons.lock_rounded,
      title:    context.tr('subscription.locked_title'),
      subtitle: context.tr('subscription.locked_subtitle'),
      action: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: () => context.push(AppRoutes.subscription),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            ),
          ),
          child: Text(
            context.tr('subscription.locked_cta'),
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
