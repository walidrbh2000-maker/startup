// lib/screens/service_request/rating_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../providers/rating_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/back_button.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RatingScreen({super.key, required this.requestId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _starLabel(BuildContext context, int stars) {
    return switch (stars) {
      1 => context.tr('rating.label_1'),
      2 => context.tr('rating.label_2'),
      3 => context.tr('rating.label_3'),
      4 => context.tr('rating.label_4'),
      5 => context.tr('rating.label_5'),
      _ => context.tr('rating.tap_to_rate'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accent       = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final state        = ref.watch(ratingControllerProvider(widget.requestId));
    final requestAsync = ref.watch(serviceRequestStreamProvider(widget.requestId));

    ref.listen<RatingState>(
      ratingControllerProvider(widget.requestId),
      (_, next) {
        if (next.success && mounted) appBack(context);
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    AppConstants.paddingMd,
                    0),
                child: Row(
                  children: [
                    AppBackButton(isDark: isDark),
                    const SizedBox(width: AppConstants.spacingMd),
                    Text(
                      context.tr('rating.title'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    AppConstants.paddingMd,
                    AppConstants.spacingXl,
                    AppConstants.paddingMd,
                    AppConstants.spacingXl +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Worker avatar + name + service type
                      requestAsync.when(
                        data: (req) => (req?.workerName?.isNotEmpty ?? false)
                            ? Column(
                                children: [
                                  Container(
                                    width:  AppConstants.avatarSizeLg,
                                    height: AppConstants.avatarSizeLg,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accentSelectedFill,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        req!.workerName![0].toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color:      accent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppConstants.spacingMd),
                                  Text(
                                    req.workerName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    context.tr('services.${req.serviceType}'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppTheme.darkSecondaryText
                                              : AppTheme.lightSecondaryText,
                                        ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error:   (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // Stars row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < state.stars;
                          return Semantics(
                            button: true,
                            label:  _starLabel(context, i + 1),
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(ratingControllerProvider(
                                          widget.requestId)
                                      .notifier)
                                  .setStars(i + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingSm),
                                child: Icon(
                                  filled
                                      ? AppIcons.ratingFilled
                                      : AppIcons.ratingOutlined,
                                  size:  AppConstants.iconSizeMdLg,
                                  color: filled
                                      ? AppTheme.warningAmber
                                      : (isDark
                                          ? AppTheme.darkSecondaryText
                                          : AppTheme.lightSecondaryText),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      AnimatedSwitcher(
                        duration: AppConstants.animDurationMicro,
                        child: Text(
                          _starLabel(context, state.stars),
                          key:   ValueKey(state.stars),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: state.stars > 0
                                    ? (isDark
                                        ? AppTheme.warningAmber
                                        : AppTheme.amberTextLight)
                                    : (isDark
                                        ? AppTheme.darkSecondaryText
                                        : AppTheme.lightSecondaryText),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingXl),

                      // Comment field
                      TextField(
                        controller:      _commentCtrl,
                        maxLines:        4,
                        maxLength:       AppConstants.maxRatingCommentLength,
                        decoration: InputDecoration(
                          hintText: context.tr('rating.comment_hint'),
                          counterStyle:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                        textInputAction: TextInputAction.done,
                      ),

                      // Error message from controller
                      if (state.errorKey != null) ...[
                        const SizedBox(height: AppConstants.spacingSm),
                        Text(
                          context.tr(state.errorKey!),
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

              // ── Submit button ────────────────────────────────────────────
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppConstants.paddingMd,
                  AppConstants.spacingSm,
                  AppConstants.paddingMd,
                  AppConstants.spacingSm +
                      MediaQuery.paddingOf(context).bottom,
                ),
                child: SizedBox(
                  width:  double.infinity,
                  height: AppConstants.buttonHeightMd,
                  child: ElevatedButton(
                    onPressed: state.canSubmit
                        ? () => ref
                            .read(ratingControllerProvider(widget.requestId)
                                .notifier)
                            .submit(
                              comment: _commentCtrl.text.trim().isEmpty
                                  ? null
                                  : _commentCtrl.text.trim(),
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                            width:  AppConstants.spinnerSizeLg,
                            height: AppConstants.spinnerSizeLg,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text(
                            context.tr('rating.submit'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:      Colors.white,
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
}
