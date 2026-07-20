// lib/screens/worker_profile/worker_profile_screen.dart
//
// Public worker profile at /worker/:id (distinct from the auth-flow
// onboarding screen). Point Final: editorial header (accent rule + avatar ring
// + name headline) over flat stat cards — no colored hero card, no gradient.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/worker_model.dart';
import '../../providers/core_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../widgets/back_button.dart';
import '../../widgets/feature_error_state.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../utils/require_auth.dart';
import '../../utils/whatsapp_launcher.dart';
import '../../widgets/app_user_avatar.dart';
import '../../widgets/wordmark.dart';

class WorkerProfileScreen extends ConsumerWidget {
  final String workerId;

  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(workerProfileProvider(workerId));
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:        Theme.of(context).colorScheme.surface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:        Colors.transparent,
          elevation:              0,
          scrolledUnderElevation: 0,
          leading: const AppBarBackButton(),
        ),
        body: workerAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorView(
            onRetry: () => ref.invalidate(workerProfileProvider(workerId)),
          ),
          data: (worker) => worker == null
              ? const _NotFoundView()
              : _ProfileBody(worker: worker, isDark: isDark),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  final WorkerModel worker;
  final bool        isDark;

  const _ProfileBody({required this.worker, required this.isDark});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _isContacting = false;

  Future<void> _openWhatsApp() async {
    if (_isContacting) return;
    // Contacting a worker is account-gated; guests get the create-account sheet.
    if (!await requireAuth(context, ref)) return;
    if (!mounted) return; // sheet may outlive this screen
    setState(() => _isContacting = true);
    try {
      final msg = context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(
        phone:   widget.worker.phoneNumber,
        message: msg,
      );
      if (!ok && mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          context.tr('whatsapp.open_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _isContacting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker  = widget.worker;
    final isDark  = widget.isDark;
    final theme   = Theme.of(context);
    final accent  = theme.colorScheme.primary;

    return CustomScrollView(
      slivers: [
        // ── Editorial header — accent rule + avatar ring + name headline ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top:   MediaQuery.paddingOf(context).top + kToolbarHeight,
              left:  AppConstants.paddingMd,
              right: AppConstants.paddingMd,
            ),
            child: Semantics(
              label:     worker.name,
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AccentRule(),
                  const SizedBox(height: AppConstants.spacingMd),
                  Row(
                    children: [
                      AppUserAvatar(
                        imageUrl:    worker.profileImageUrl,
                        name:        worker.name,
                        radius:      36,
                        borderColor: accent,
                        borderWidth: 2,
                      ),
                      const SizedBox(width: AppConstants.paddingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight:    FontWeight.w700,
                                letterSpacing:
                                    Localizations.localeOf(context)
                                                .languageCode == 'ar'
                                        ? 0.0
                                        : -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppConstants.spacingXs),
                            Text(
                              context.tr('services.${worker.profession}'),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppConstants.spacingSm),
                            _OnlineBadge(isOnline: worker.isOnline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Stats + CTA ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.spacingLg),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        isDark: isDark,
                        label:  context.tr('worker_preview.rating'),
                        child:  _StarRating(
                          rating: worker.averageRating,
                          count:  worker.ratingCount,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: _StatCard(
                        isDark: isDark,
                        label:  context.tr('worker_preview.reviews'),
                        child: Text(
                          '${worker.ratingCount}',
                          style: TextStyle(
                            fontSize:   AppConstants.fontSizeXxl,
                            fontWeight: FontWeight.w700,
                            color:      accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.spacingXl),

                // ── WhatsApp CTA ──────────────────────────────────────
                Semantics(
                  label:  context.tr('worker_preview.contact_worker'),
                  button: true,
                  child: SizedBox(
                    width:  double.infinity,
                    height: AppConstants.buttonHeight,
                    child: ElevatedButton(
                      onPressed:
                          _isContacting ? null : _openWhatsApp,
                      style: ElevatedButton.styleFrom(
                        // Use AppTheme token for dark surface
                        backgroundColor: isDark
                            ? AppTheme.whatsAppDarkSurface
                            : Colors.white,
                        foregroundColor: isDark
                            ? AppTheme.whatsAppGreen
                            : AppTheme.whatsAppDeep,
                        disabledBackgroundColor: isDark
                            ? AppTheme.whatsAppDarkSurface
                                .withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.4),
                        elevation: 0,
                        side: BorderSide(
                          color: AppTheme.whatsAppGreen.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusMd),
                        ),
                      ),
                      child: _isContacting
                          ? SizedBox(
                              width:  AppConstants.spinnerSizeLg,
                              height: AppConstants.spinnerSizeLg,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:       isDark
                                    ? AppTheme.whatsAppGreen
                                    : AppTheme.whatsAppDeep,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                // Natural icon — NO color tint
                                WhatsAppIcon(size: AppConstants.iconSizeMd),
                                const SizedBox(width: AppConstants.spacingSm),
                                Text(
                                  context.tr(
                                      'worker_preview.contact_worker'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color:      isDark
                                        ? AppTheme.whatsAppGreen
                                        : AppTheme.whatsAppDeep,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRIVATE WIDGETS
// ============================================================================

class _OnlineBadge extends StatelessWidget {
  final bool isOnline;
  const _OnlineBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  AppConstants.statusDotSize,
          height: AppConstants.statusDotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? AppTheme.onlineGreen : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          context.tr(
              isOnline ? 'worker_home.online' : 'worker_home.offline'),
          style: theme.textTheme.labelSmall?.copyWith(
            color:      isOnline ? AppTheme.onlineGreen : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool   isDark;
  final String label;
  final Widget child;

  const _StatCard(
      {required this.isDark, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: AppConstants.cardBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppConstants.spacingXs),
          child,
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final int    count;

  const _StarRating({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < rating.floor();
            final half   = !filled && i < rating;
            return Icon(
              half
                  ? AppIcons.starHalf
                  : filled
                      ? AppIcons.star
                      : AppIcons.starOutlined,
              size:  18,
              color: accent,
            );
          }),
        ),
        const SizedBox(height: AppConstants.spacingXxs),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => FeatureErrorState(
        isDark:     Theme.of(context).brightness == Brightness.dark,
        errorTitle: context.tr('common.error'),
        onRetry:    onRetry,
        retryLabel: context.tr('common.retry'),
      );
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.person,
                size:  AppConstants.iconSizeLg2,
                color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: AppConstants.paddingMd),
            Text(context.tr('worker_preview.not_found'),
                style:     theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
