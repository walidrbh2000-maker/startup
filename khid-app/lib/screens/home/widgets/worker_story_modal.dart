// lib/screens/home/widgets/worker_story_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/worker_home_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_chrome.dart';
import 'home_worker_section.dart';

// ─── Dimensions ───────────────────────────────────────────────────────────────
// _kTopPeek: the visible top strip of the screen that shows through the barrier
// when the modal is fully open. 72dp = status bar (~24dp) + a comfortable peek
// gap. If this ever needs to match another modal, promote to AppConstants.modalTopPeek.
const double _kTopPeek         = 72.0;
const double _kTopRadius       = AppConstants.radiusXxl;
const double _kDismissVelocity = 400.0;

// ============================================================================
// WORKER STORY MODAL
// ============================================================================

class WorkerStoryModal {
  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque:             false,
        barrierColor:       AppTheme.overlayDark,
        barrierDismissible: true,
        transitionDuration:        AppConstants.animDurationShort,
        reverseTransitionDuration: AppConstants.animDurationShort,
        pageBuilder: (_, __, ___) => const _WorkerStoryPage(),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end:   Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve:  Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class _WorkerStoryPage extends ConsumerStatefulWidget {
  const _WorkerStoryPage();

  @override
  ConsumerState<_WorkerStoryPage> createState() => _WorkerStoryPageState();
}

class _WorkerStoryPageState extends ConsumerState<_WorkerStoryPage> {
  double _dragOffset = 0.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() => _dragOffset += details.delta.dy);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity > _kDismissVelocity || _dragOffset > 160) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final isOnline   = ref.watch(
      workerHomeControllerProvider.select((s) => s.isOnline),
    );
    final statusColor = isOnline
        ? AppTheme.onlineGreen
        : AppTheme.recordingRed;

    final bg     = isDark ? AppTheme.darkBackground  : AppTheme.lightBackground;
    final border = isDark ? AppTheme.darkBorder       : AppTheme.lightBorder;
    final text   = isDark ? AppTheme.darkText         : AppTheme.lightText;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Column(
          children: [
            const SizedBox(height: _kTopPeek),

            Expanded(
              child: GestureDetector(
                onTap: () {},
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd:    _onDragEnd,
                child: Transform.translate(
                  offset: Offset(0, _dragOffset.clamp(0.0, 200.0)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_kTopRadius),
                      ),
                      boxShadow: [
                        isDark
                            ? AppTheme.modalShadowDark
                            : AppTheme.modalShadowLight,
                      ],
                    ),
                    child: Column(
                      children: [
                        // ── Drag handle ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(
                            top:    AppConstants.spacingMd,
                            bottom: AppConstants.spacingXs,
                          ),
                          child: const SheetHandle(),
                        ),

                        // ── Header ──────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingLg,
                            vertical:   AppConstants.spacingSm,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: AppConstants.animDurationMicro,
                                width:  AppConstants.statusDotSize,
                                height: AppConstants.statusDotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSm),

                              Text(
                                context.tr('worker_home.story_title'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      letterSpacing: -0.4,
                                      color:         text,
                                    ),
                              ),

                              const Spacer(),

                              AnimatedContainer(
                                duration: AppConstants.animDurationMicro,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingMd,
                                  vertical:   AppConstants.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(
                                    alpha: isDark ? 0.15 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusCircle,
                                  ),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.30),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  isOnline
                                      ? context.tr('worker_home.status_online')
                                      : context.tr('worker_home.status_offline'),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color:      isOnline
                                            ? (isDark
                                                ? AppTheme.onlineGreen
                                                : AppTheme.greenTextLight)
                                            : (isDark
                                                ? AppTheme.recordingRed
                                                : AppTheme.lightError),
                                      ),
                                ),
                              ),

                              const SizedBox(width: AppConstants.spacingSm),

                              SheetCloseButton(
                                semanticsLabel: context.tr('common.close'),
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),

                        // ── Worker content — scrollable ──────────────────
                        const Expanded(
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: HomeWorkerSection(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
