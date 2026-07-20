// lib/widgets/pin_promo_banner.dart
//
// One-time, dismissible "protect your account" banner recommending the
// optional account PIN. Shown only when: real account (not guest), account
// installed ≥ 7 days ago, no PIN yet, never dismissed. Nothing is forced —
// the PIN stays opt-in (settings) per product decision.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/core_providers.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

class PinPromoBanner extends ConsumerStatefulWidget {
  const PinPromoBanner({super.key});

  @override
  ConsumerState<PinPromoBanner> createState() => _PinPromoBannerState();
}

class _PinPromoBannerState extends ConsumerState<PinPromoBanner> {
  static const _dismissedKey  = 'pin_promo_dismissed';
  static const _firstSeenKey  = 'pin_promo_first_seen_ms';
  static const _minAge        = Duration(days: 7);

  bool _show = false;

  @override
  void initState() {
    super.initState();
    _evaluate();
  }

  Future<void> _evaluate() async {
    final auth = ref.read(authServiceProvider);
    if (!auth.isLoggedIn || auth.isGuest) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) ?? false) return;

    // Age gate: first evaluation stamps the clock; the banner appears on a
    // later launch once 7 days have passed — no interruption on day one.
    final firstSeen = prefs.getInt(_firstSeenKey);
    if (firstSeen == null) {
      await prefs.setInt(_firstSeenKey, DateTime.now().millisecondsSinceEpoch);
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch - firstSeen < _minAge.inMilliseconds) {
      return;
    }

    try {
      final check = await ref
          .read(apiServiceProvider)
          .checkAuthUser(auth.user?.uid ?? '');
      if (check.hasPin || check.isNewUser) return;
    } catch (_) {
      return; // network issue — try again next launch, never block home
    }

    if (mounted) setState(() => _show = true);
  }

  Future<void> _dismiss() async {
    setState(() => _show = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          onTap: () {
            _dismiss();
            context.push(AppRoutes.accountPin);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMd,
              vertical:   AppConstants.paddingSm,
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: AppConstants.iconSizeSm,
                    color: theme.colorScheme.primary),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    context.tr('pin.promo'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded,
                      size: AppConstants.iconSizeSm,
                      color: theme.colorScheme.primary),
                  onPressed: _dismiss,
                  tooltip: context.tr('common.close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
