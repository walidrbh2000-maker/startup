// lib/screens/worker_jobs/submit_bid_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/worker_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/back_button.dart';
import '../subscription/widgets/subscription_locked_view.dart';

class SubmitBidScreen extends ConsumerStatefulWidget {
  final String requestId;

  const SubmitBidScreen({super.key, required this.requestId});

  @override
  ConsumerState<SubmitBidScreen> createState() => _SubmitBidScreenState();
}

class _SubmitBidScreenState extends ConsumerState<SubmitBidScreen> {
  final _priceCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  int      _estimatedHours   = 1;
  int      _estimatedMinutes = 0;
  DateTime _availableFrom    = DateTime.now();

  bool    _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  int get _totalEstimatedMinutes => _estimatedHours * 60 + _estimatedMinutes;

  Future<void> _submit(WorkerModel worker) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;
    if (!mounted) return;

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(workerBidServiceProvider).submitBid(
            requestId:        widget.requestId,
            worker:           worker,
            proposedPrice:    price,
            estimatedMinutes: _totalEstimatedMinutes,
            availableFrom:    _availableFrom,
            message: _messageCtrl.text.trim().isEmpty
                ? null
                : _messageCtrl.text.trim(),
          );

      if (!mounted) return;
      appBack(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        // Translation key — rendered via context.tr() in build().
        _errorMessage = errorKeyFor(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    // Deep links (notification taps) reach this route without passing the
    // jobs-tab paywall — enforce the same lock here. The backend gate is
    // authoritative (403 on unsubscribed bids); loading/error fall through
    // so a transient fetch failure never blocks a subscribed worker.
    final userDoc = ref.watch(currentUserDocProvider);
    // Locked when: no active subscription, pack without bid access (Basic /
    // custom 0 bids), or monthly bid quota exhausted. The backend re-enforces
    // all three (consumeBid) — this is just the honest UI.
    final me = userDoc.value;
    final bidsLeft = me?.bidsRemainingAt(DateTime.now());
    if (userDoc.hasValue &&
        (!(me?.isSubscribed ?? false) || !(me?.canBid ?? true) || bidsLeft == 0)) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemOverlayStyle(isDark),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Row(
                    children: [AppBackButton(isDark: isDark)],
                  ),
                ),
                const Expanded(child: SubscriptionLockedView()),
              ],
            ),
          ),
        ),
      );
    }

    final workerId     = ref.watch(currentUserIdProvider);
    final workerAsync  = workerId != null
        ? ref.watch(workerProfileProvider(workerId))
        : null;
    final requestAsync = ref.watch(serviceRequestStreamProvider(widget.requestId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingMd,
                  AppConstants.paddingMd,
                  AppConstants.paddingMd,
                  0,
                ),
                child: Row(
                  children: [
                    AppBackButton(isDark: isDark),
                    const SizedBox(width: AppConstants.spacingMd),
                    Text(
                      context.tr('worker_browse.make_offer'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Request summary ───────────────────────────────
                        requestAsync.when(
                          loading: () => const _RequestSummarySkeletonCard(),
                          error: (_, __) => _RequestSummaryError(
                            isDark: isDark,
                            accent: accent,
                          ),
                          data: (req) {
                            if (req == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingMd),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusLg),
                                border: Border.all(
                                    color: AppTheme.accentBorderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(
                                        'services.${req.serviceType}'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  if (req.userAddress.isNotEmpty)
                                    Text(
                                      req.userAddress,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppTheme.darkSecondaryText
                                                : AppTheme
                                                    .lightSecondaryText,
                                          ),
                                    ),
                                  if (req.displayAmount != null)
                                    Text(
                                      '${context.tr('bids.budget')}: ${req.displayAmount} ${context.tr('common.currency')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppTheme.darkAccentText
                                                : accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppConstants.spacingMd),

                        // ── Price field ───────────────────────────────────
                        _FieldLabel(
                          text: context.tr('worker_browse.proposed_price'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText:   '3500',
                            suffixText: context.tr('common.currency'),
                            suffixStyle:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return context
                                  .tr('worker_browse.price_required');
                            }
                            final p = double.tryParse(v);
                            if (p == null || p <= 0) {
                              return context
                                  .tr('worker_browse.price_invalid');
                            }
                            if (p > AppConstants.maxBidPrice) {
                              return context
                                  .tr('worker_browse.price_too_high');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppConstants.spacingMd),

                        // ── Estimated duration ────────────────────────────
                        _FieldLabel(
                          text: context.tr('worker_browse.estimated_duration'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Row(
                          children: [
                            Expanded(
                              child: _DurationPicker(
                                value:     _estimatedHours,
                                max:       23,
                                label:     context.tr('worker_browse.hours'),
                                isDark:    isDark,
                                onChanged: (v) =>
                                    setState(() => _estimatedHours = v),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingMd),
                            Expanded(
                              child: _DurationPicker(
                                value:     _estimatedMinutes,
                                max:       55,
                                step:      5,
                                label:     context.tr('worker_browse.minutes'),
                                isDark:    isDark,
                                onChanged: (v) =>
                                    setState(() => _estimatedMinutes = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.spacingMd),

                        // ── Message (optional) ────────────────────────────
                        _FieldLabel(
                          text:
                              '${context.tr('worker_browse.message')} (${context.tr('common.optional')})',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        TextFormField(
                          controller: _messageCtrl,
                          maxLines:   3,
                          maxLength:  AppConstants.maxBidMessageLength,
                          decoration: InputDecoration(
                            hintText: context
                                .tr('worker_browse.message_hint'),
                            counterStyle:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),

                        // ── Error message ─────────────────────────────────
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppConstants.spacingSm),
                          Text(
                            context.tr(_errorMessage!),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkError
                                      : AppTheme.lightError,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Submit button ─────────────────────────────────────────
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppConstants.paddingMd,
                  AppConstants.spacingSm,
                  AppConstants.paddingMd,
                  AppConstants.spacingSm +
                      MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Monthly bid quota — shown only for finite-quota packs.
                    if (bidsLeft != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spacingSm),
                        child: Text(
                          context
                              .tr('worker_browse.bids_remaining')
                              .replaceFirst('{n}', '$bidsLeft'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                        ),
                      ),
                    workerAsync?.when(
                      data: (worker) => worker != null
                          ? Semantics(
                              button: true,
                              label: context.tr('worker_browse.submit_offer'),
                              child: SizedBox(
                                width:  double.infinity,
                                height: AppConstants.buttonHeightMd,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _submit(worker),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.radiusMd),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width:  AppConstants.spinnerSizeLg,
                                          height: AppConstants.spinnerSizeLg,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          context.tr(
                                              'worker_browse.submit_offer'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox(
                        height: AppConstants.buttonHeightMd,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ) ??
                        const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _RequestSummarySkeletonCard
// ============================================================================

class _RequestSummarySkeletonCard extends StatelessWidget {
  const _RequestSummarySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: SkeletonBone(
        width:  double.infinity,
        height: AppConstants.skeletonCardHeight,
        radius: AppConstants.radiusLg,
      ),
    );
  }
}

// ============================================================================
// _RequestSummaryError
// ============================================================================

class _RequestSummaryError extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _RequestSummaryError({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkError : AppTheme.lightError)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: (isDark ? AppTheme.darkError : AppTheme.lightError)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        context.tr('errors.loading_request'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.darkError : AppTheme.lightError,
            ),
      ),
    );
  }
}

// ============================================================================
// _FieldLabel
// ============================================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _FieldLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ============================================================================
// _DurationPicker
// ============================================================================

class _DurationPicker extends StatelessWidget {
  final int value;
  final int max;
  final int step;
  final String label;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _DurationPicker({
    required this.value,
    required this.max,
    this.step = 1,
    required this.label,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSmMd,
        vertical:   AppConstants.paddingSm,
      ),
      decoration: BoxDecoration(
        color:        surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: value > 0
                ? () => onChanged((value - step).clamp(0, max))
                : null,
            child: Icon(
              AppIcons.remove,
              size: 18,
              color: value > 0
                  ? (isDark ? AppTheme.darkText : AppTheme.lightText)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          ),
          Column(
            children: [
              Text(
                value.toString().padLeft(2, '0'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
              ),
            ],
          ),
          GestureDetector(
            onTap: value < max
                ? () => onChanged((value + step).clamp(0, max))
                : null,
            child: Icon(
              AppIcons.add,
              size: 18,
              color: value < max
                  ? (isDark ? AppTheme.darkText : AppTheme.lightText)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          ),
        ],
      ),
    );
  }
}
