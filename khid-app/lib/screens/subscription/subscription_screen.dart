// lib/screens/subscription/subscription_screen.dart
//
// Visibility subscription (business model: the worker pays to be visible, no
// commission on transactions). One screen used in two places:
//   • Worker signup offer → context.go (skip → /home)
//   • Paywall from worker_jobs → context.push (skip → pop)
// "Later" pops if it can, otherwise goes to /home.
//
// Packs (the protected bid channel is the real product; map hours are the
// anti-squatting mechanism; all packs are 7/7):
//   Basic    500  — map 5 h/day, NO bids (sees direct requests)
//   Pro     1000  — map 10 h/day, 20 bids/month
//   Business 1500 — unlimited map + bids, search priority, Pro badge
//   Expert  2500  — everything Business + B2B flux (verified docs required)
//   Custom 500–2550 — sliders (hours 5–15, bids 0–30 at 25 DA/unit) plus
//   priority (+200) and B2B (+850, docs required) toggles.
// Pricing mirrors CUSTOM_PACK / TIER_PACKS in the backend user.schema.ts —
// the server reprices on activation, the client only previews.
//
// ponytail: payment stub — activateSubscription() flags the sub active on the
// backend with no gateway. Wire SATIM here when available.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../utils/localization.dart';
import '../../widgets/back_button.dart';
import '../../widgets/wordmark.dart';

// Custom pack pricing — MUST match CUSTOM_PACK in backend user.schema.ts.
const int _kCustomBase     = 500;
const int _kCustomPerH     = 25;
const int _kCustomPerBid   = 25;
const int _kCustomPriority = 200;
const int _kCustomB2b      = 850;
const int _kHoursMin = 5,  _kHoursMax = 15;
const int _kBidsMin  = 0,  _kBidsMax  = 30;

int _customPrice(int hours, int bids, {bool priority = false, bool b2b = false}) =>
    _kCustomBase +
    (hours - _kHoursMin) * _kCustomPerH +
    bids * _kCustomPerBid +
    (priority ? _kCustomPriority : 0) +
    (b2b ? _kCustomB2b : 0);

/// Static spec of one preset pack.
class _Plan {
  final String tier;      // backend id: basic | pro | business | expert
  final int    priceDa;
  final String nameKey;
  final String descKey;   // one-line quota summary, always visible
  final String? badgeKey; // RECOMMANDÉ / FLUX B2B
  final List<String> featureKeys;

  const _Plan({
    required this.tier,
    required this.priceDa,
    required this.nameKey,
    required this.descKey,
    this.badgeKey,
    required this.featureKeys,
  });
}

const List<_Plan> _kPlans = [
  _Plan(
    tier: 'basic',
    priceDa: 500,
    nameKey: 'subscription.plan_basic_name',
    descKey: 'subscription.plan_basic_desc',
    featureKeys: [
      'subscription.feature_visibility',
      'subscription.feature_requests',
      'subscription.feature_no_commission',
    ],
  ),
  _Plan(
    tier: 'pro',
    priceDa: 1000,
    nameKey: 'subscription.plan_pro_name',
    descKey: 'subscription.plan_pro_desc',
    featureKeys: [
      'subscription.feature_visibility',
      'subscription.feature_requests',
      'subscription.feature_bid_20',
      'subscription.feature_no_commission',
    ],
  ),
  _Plan(
    tier: 'business',
    priceDa: 1500,
    nameKey: 'subscription.plan_business_name',
    descKey: 'subscription.plan_business_desc',
    badgeKey: 'subscription.plan_badge',
    featureKeys: [
      'subscription.feature_visibility',
      'subscription.feature_requests',
      'subscription.feature_bid_unlimited',
      'subscription.feature_priority',
      'subscription.feature_badge',
      'subscription.feature_no_commission',
    ],
  ),
  _Plan(
    tier: 'expert',
    priceDa: 2500,
    nameKey: 'subscription.plan_expert_name',
    descKey: 'subscription.plan_expert_desc',
    badgeKey: 'subscription.plan_expert_badge',
    featureKeys: [
      'subscription.feature_visibility',
      'subscription.feature_requests',
      'subscription.feature_bid_unlimited',
      'subscription.feature_priority',
      'subscription.feature_badge',
      'subscription.feature_b2b',
      'subscription.feature_no_commission',
    ],
  ),
];

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _loading = false;
  String _tier = 'business'; // recommended pack pre-selected
  int _customHours = 8;      // custom sliders (only sent when _tier == custom)
  int _customBids  = 10;
  bool _customPriority = false; // custom add-ons
  bool _customB2b      = false;

  void _dismiss() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  int get _selectedPrice => _tier == 'custom'
      ? _customPrice(_customHours, _customBids,
          priority: _customPriority, b2b: _customB2b)
      : _kPlans.firstWhere((p) => p.tier == _tier).priceDa;

  /// B2B (expert preset or custom toggle) requires admin-verified documents.
  bool get _wantsB2b => _tier == 'expert' || (_tier == 'custom' && _customB2b);

  /// Smart doc gate: if the worker wants B2B without verified docs, offer to
  /// take them to the document submission flow (worker profile setup, where
  /// the optional DocumentPickerWidget lives). Mirrors the backend 403
  /// DOCS_REQUIRED_FOR_B2B — this is just the friendly path.
  Future<void> _promptForDocs() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('subscription.docs_needed_title')),
        content: Text(ctx.tr('subscription.docs_needed_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('subscription.docs_needed_cta')),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      context.push(AppRoutes.workerProfileSetup);
    }
  }

  Future<void> _subscribe() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _loading) return;

    // Client-side doc gate (backend re-enforces with DOCS_REQUIRED_FOR_B2B).
    if (_wantsB2b) {
      final me = ref.read(currentUserDocProvider).value;
      if (me != null && !me.isVerified) {
        await _promptForDocs();
        return;
      }
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(firestoreServiceProvider).activateSubscription(
            user.uid,
            tier: _tier,
            hoursPerDay: _customHours,
            bidsPerMonth: _customBids,
            priority: _customPriority,
            b2b: _customB2b,
          );
      ref.invalidate(currentUserDocProvider); // refresh the gates
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ErrorHandler.showSuccessSnackBar(
        context,
        context.tr('subscription.success'),
      );
      _dismiss();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Doc gate hit on the server (stale local doc) → same friendly path.
      if (errorKeyFor(e) == 'errors.docs_required_b2b') {
        await _promptForDocs();
        return;
      }
      ErrorHandler.showErrorSnackBar(
        context,
        context.tr('subscription.error'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final text   = isDark ? AppTheme.darkText   : AppTheme.lightText;
    final subtle = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      // Signup offer arrives with go() (empty stack) — route system back
      // through _dismiss so it skips to home instead of exiting the app.
      // From the paywall (push) canPop is true and back pops normally.
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar: back + title + skip ──────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMd),
                child: Row(
                  children: [
                    AppBackButton(onPressed: _dismiss, isDark: isDark),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: PointFinalTitle(context.tr('subscription.title')),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _dismiss,
                      child: Text(
                        context.tr('subscription.later'),
                        style: TextStyle(color: subtle),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.paddingLg, 0,
                    AppConstants.paddingLg, AppConstants.paddingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppConstants.spacingSm),

                      // Title lives in the top bar beside the back button.
                      Text(
                        context.tr('subscription.subtitle'),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: subtle, height: 1.5),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // ── Preset cards + custom builder ─────────────────
                      for (final (i, plan) in _kPlans.indexed) ...[
                        if (i > 0)
                          const SizedBox(height: AppConstants.spacingMd),
                        _stagger(
                          i,
                          reduceMotion,
                          _PlanCard(
                            isDark: isDark,
                            accent: accent,
                            text: text,
                            subtle: subtle,
                            plan: plan,
                            isSelected: _tier == plan.tier,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tier = plan.tier);
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: AppConstants.spacingMd),
                      _stagger(
                        _kPlans.length,
                        reduceMotion,
                        _CustomPlanCard(
                          isDark: isDark,
                          accent: accent,
                          text: text,
                          subtle: subtle,
                          isSelected: _tier == 'custom',
                          hours: _customHours,
                          bids: _customBids,
                          priority: _customPriority,
                          b2b: _customB2b,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _tier = 'custom');
                          },
                          onHours: (v) => setState(() {
                            _tier = 'custom';
                            _customHours = v;
                          }),
                          onBids: (v) => setState(() {
                            _tier = 'custom';
                            _customBids = v;
                          }),
                          onPriority: (v) => setState(() {
                            _tier = 'custom';
                            _customPriority = v;
                          }),
                          onB2b: (v) => setState(() {
                            _tier = 'custom';
                            _customB2b = v;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── CTA (shows the live price) ────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLg),
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _loading ? null : _subscribe,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusLg),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            '${context.tr('subscription.cta')} · '
                            '$_selectedPrice ${context.tr('subscription.price_period')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Staggered entrance, one delay step per card.
  Widget _stagger(int index, bool reduceMotion, Widget card) {
    if (reduceMotion) return card;
    final delay = (150 + index * 110).ms;
    return card.animate().fade(delay: delay, duration: 500.ms).slideY(
          begin: 0.15,
          end: 0,
          delay: delay,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}

// ============================================================================
// _CardShell — shared selectable-card chrome (border, wash, radio).
// ============================================================================

class _CardShell extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;
  final String semanticsLabel;
  final Widget child;

  const _CardShell({
    required this.isDark,
    required this.accent,
    required this.isSelected,
    required this.onTap,
    required this.semanticsLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border  = isDark ? AppTheme.darkBorder  : AppTheme.lightBorder;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animDurationMicro,
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          decoration: BoxDecoration(
            // Selected → faint accent wash; the border carries selection, no glow.
            color: isSelected ? accent.withValues(alpha: 0.06) : surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(
              color: isSelected ? accent : border,
              width: isSelected ? 2 : 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================================
// _PlanCard — collapsed: name + price + quota line. Selected: + feature list.
// ============================================================================

class _PlanCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final Color text;
  final Color subtle;
  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.isDark,
    required this.accent,
    required this.text,
    required this.subtle,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      isDark: isDark,
      accent: accent,
      isSelected: isSelected,
      onTap: onTap,
      semanticsLabel: context.tr(plan.nameKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge (recommended / expert)
          if (plan.badgeKey != null) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSm, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  context.tr(plan.badgeKey!),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkAccentText : accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
          ],

          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(plan.nameKey),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: text, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? accent : subtle,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),

          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${plan.priceDa}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: text,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('subscription.price_period'),
                style: TextStyle(color: subtle, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),

          // Quota line — always visible so the packs compare at a glance.
          Text(
            context.tr(plan.descKey),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: subtle, height: 1.35),
          ),

          // Feature list — expands on the selected card only.
          AnimatedSize(
            duration: AppConstants.animDurationMicro,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !isSelected
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppConstants.spacingLg),
                      for (final key in plan.featureKeys)
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingSm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 20, color: accent),
                              const SizedBox(width: AppConstants.spacingSm),
                              Expanded(
                                child: Text(
                                  context.tr(key),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: text, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _CustomPlanCard — "shape your own pack": hours + bids sliders, priority and
// B2B add-on toggles, live price. 500 DA floor … 2550 DA fully loaded (the
// Expert preset at 2500 stays the better deal — by design).
// ============================================================================

class _CustomPlanCard extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final Color text;
  final Color subtle;
  final bool isSelected;
  final int hours;
  final int bids;
  final bool priority;
  final bool b2b;
  final VoidCallback onTap;
  final ValueChanged<int> onHours;
  final ValueChanged<int> onBids;
  final ValueChanged<bool> onPriority;
  final ValueChanged<bool> onB2b;

  const _CustomPlanCard({
    required this.isDark,
    required this.accent,
    required this.text,
    required this.subtle,
    required this.isSelected,
    required this.hours,
    required this.bids,
    required this.priority,
    required this.b2b,
    required this.onTap,
    required this.onHours,
    required this.onBids,
    required this.onPriority,
    required this.onB2b,
  });

  @override
  Widget build(BuildContext context) {
    final price = _customPrice(hours, bids, priority: priority, b2b: b2b);

    return _CardShell(
      isDark: isDark,
      accent: accent,
      isSelected: isSelected,
      onTap: onTap,
      semanticsLabel: context.tr('subscription.plan_custom_name'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('subscription.plan_custom_name'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: text, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? accent : subtle,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),

          // Live price — animates as the sliders move.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedSwitcher(
                duration: AppConstants.animDurationMicro,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  '$price',
                  key: ValueKey(price),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('subscription.price_period'),
                style: TextStyle(color: subtle, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            context.tr('subscription.plan_custom_desc'),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: subtle, height: 1.35),
          ),

          // Sliders — expand when the card is selected.
          AnimatedSize(
            duration: AppConstants.animDurationMicro,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !isSelected
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppConstants.spacingLg),
                      _sliderRow(
                        context,
                        icon: Icons.schedule_rounded,
                        label: context
                            .tr('subscription.custom_hours')
                            .replaceFirst('{n}', '$hours'),
                        value: hours,
                        min: _kHoursMin,
                        max: _kHoursMax,
                        onChanged: onHours,
                      ),
                      _sliderRow(
                        context,
                        icon: Icons.gavel_rounded,
                        label: context
                            .tr('subscription.custom_bids')
                            .replaceFirst('{n}', '$bids'),
                        value: bids,
                        min: _kBidsMin,
                        max: _kBidsMax,
                        onChanged: onBids,
                      ),
                      if (bids == 0)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: AppConstants.spacingXs),
                          child: Text(
                            context.tr('subscription.custom_no_bids_hint'),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.warningAmber
                                      : AppTheme.amberTextLight,
                                ),
                          ),
                        ),
                      const SizedBox(height: AppConstants.spacingSm),

                      // Add-on toggles: priority (+200) and B2B (+850, docs
                      // required — the subscribe flow routes to the document
                      // screen when the account is not verified yet).
                      _toggleRow(
                        context,
                        icon: Icons.trending_up_rounded,
                        label: context
                            .tr('subscription.custom_priority')
                            .replaceFirst('{price}', '$_kCustomPriority'),
                        value: priority,
                        onChanged: onPriority,
                      ),
                      _toggleRow(
                        context,
                        icon: Icons.business_center_rounded,
                        label: context
                            .tr('subscription.custom_b2b')
                            .replaceFirst('{price}', '$_kCustomB2b'),
                        value: b2b,
                        onChanged: onB2b,
                      ),
                      if (b2b)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: AppConstants.spacingXs),
                          child: Text(
                            context.tr('subscription.custom_b2b_docs_hint'),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: subtle),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: AppConstants.spacingXs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: text,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Switch(
          value: value,
          activeColor: accent,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _sliderRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: AppConstants.spacingXs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: accent,
          onChanged: (v) {
            final next = v.round();
            if (next != value) {
              HapticFeedback.selectionClick();
              onChanged(next);
            }
          },
        ),
      ],
    );
  }
}
