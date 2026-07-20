// lib/screens/home/widgets/voice_search_sheet.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_search_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_chrome.dart';
import 'search_result_card.dart';

// ============================================================================
// VOICE SEARCH SHEET
// ============================================================================

const int _kMaxRecordingSeconds = 30;

// Orb sizes — all on 8dp grid.
const double _kOrbOuter  = 88.0;
const double _kOrbMid    = 72.0;
const double _kOrbInner  = 56.0;

const double _kOrbSpinnerSize = 24.0;

class VoiceSearchSheet extends StatelessWidget {
  const VoiceSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const VoiceSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => const _VoiceSheetBody();
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _VoiceSheetBody extends ConsumerStatefulWidget {
  const _VoiceSheetBody();

  @override
  ConsumerState<_VoiceSheetBody> createState() => _VoiceSheetBodyState();
}

class _VoiceSheetBodyState extends ConsumerState<_VoiceSheetBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  late final HomeSearchController _searchNotifier;

  Timer?   _elapsedTimer;
  Timer?   _autoStopTimer;
  int      _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();

    _searchNotifier = ref.read(homeSearchControllerProvider.notifier);

    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchNotifier.startListening();
      _startElapsedTimer();
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _autoStopTimer?.cancel();
    _pulseCtrl.dispose();

    if (_searchNotifier.mounted) {
      _searchNotifier.reset();
    }

    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _autoStopTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });

    _autoStopTimer = Timer(
      Duration(seconds: _kMaxRecordingSeconds),
      () {
        if (mounted &&
            ref.read(homeSearchControllerProvider).status ==
                HomeSearchStatus.listening) {
          _stopAndProcess();
        }
      },
    );
  }

  void _stopTimers() {
    _elapsedTimer?.cancel();
    _autoStopTimer?.cancel();
    _elapsedTimer  = null;
    _autoStopTimer = null;
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _stopAndProcess() {
    _stopTimers();
    _searchNotifier.stopListening();
  }

  void _retryListening() {
    _stopTimers();
    _searchNotifier.reset();
    _searchNotifier.startListening();
    _startElapsedTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final onPrimary   = Theme.of(context).colorScheme.onPrimary;
    final searchState = ref.watch(homeSearchControllerProvider);
    final isListening = searchState.status == HomeSearchStatus.listening;
    final isLoading   = searchState.isLoading;
    final hasResult   = searchState.hasResults;
    final hasError    = searchState.hasError;
    final intent      = searchState.lastIntent;

    return Container(
      decoration: BoxDecoration(
        color:        isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLg,
            vertical:   AppConstants.paddingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────────────
              const SheetHandle(),
              const SizedBox(height: AppConstants.spacingLg),

              // ── Status label ──────────────────────────────────────────────
              Text(
                searchState.status == HomeSearchStatus.idle
                    ? context.tr('home.voice_starting')
                    : isListening
                        ? '$_elapsedLabel  •  ${context.tr('home.voice_listening')}'
                        : isLoading
                            ? context.tr('home.voice_processing')
                            : hasResult
                                ? context.tr('home.voice_done')
                                : hasError
                                    ? context.tr('home.voice_error')
                                    : context.tr('home.voice_starting'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isLoading || hasResult
                          ? AppTheme.aiPrimary
                          : (isDark ? AppTheme.darkAccentText : accent),
                    ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // ── Orb ───────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _pulse,
                builder:   (_, child) => Transform.scale(
                  scale: isListening ? _pulse.value : 1.0,
                  child: child,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width:  _kOrbOuter,
                      height: _kOrbOuter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isLoading || hasResult
                                ? AppTheme.aiPrimary
                                : accent)
                            .withValues(alpha: 0.12),
                      ),
                    ),
                    Container(
                      width:  _kOrbMid,
                      height: _kOrbMid,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isLoading || hasResult
                                ? AppTheme.aiPrimary
                                : accent)
                            .withValues(alpha: 0.20),
                      ),
                    ),
                    Container(
                      width:  _kOrbInner,
                      height: _kOrbInner,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLoading || hasResult
                            ? AppTheme.aiPrimary
                            : accent,
                      ),
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                width:  _kOrbSpinnerSize,
                                height: _kOrbSpinnerSize,
                                child:  CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: onPrimary,
                                ),
                              )
                            : Icon(
                                hasResult ? AppIcons.ai : AppIcons.mic,
                                size:  AppConstants.iconSizeMd,
                                color: onPrimary,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // ── Waveform (listening only) ─────────────────────────────────
              if (isListening)
                _Waveform(color: accent, isAnimating: true),

              const SizedBox(height: AppConstants.spacingMd),

              // ── Recording feedback ────────────────────────────────────────
              SizedBox(
                height: AppConstants.buttonHeightMd,
                child: Center(
                  child: isListening
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _elapsedLabel,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkText
                                        : AppTheme.lightText,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                            ),
                            Text(
                              'max $_kMaxRecordingSeconds s',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkSecondaryText
                                        : AppTheme.lightSecondaryText,
                                  ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // ── Result confirm ────────────────────────────────────────────
              if (hasResult && intent != null) ...[
                SearchResultCard(
                  intent:       intent,
                  isDark:       isDark,
                  showTopLabel: false,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _retryListening,
                        icon:  const Icon(AppIcons.mic, size: 16),
                        label: Text(context.tr('home.voice_retry')),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _searchNotifier.applyToMap();
                          Navigator.pop(context);
                        },
                        child: Text(context.tr('home.ai_search_see_workers')),
                      ),
                    ),
                  ],
                ),
              ]

              // ── Error ──────────────────────────────────────────────────────
              else if (hasError) ...[
                Text(
                  searchState.error == 'mic_unavailable'
                      ? context.tr('home.voice_mic_unavailable')
                      : context.tr('home.search_error'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.darkError : AppTheme.lightError,
                      ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                ElevatedButton.icon(
                  onPressed: _retryListening,
                  icon:  const Icon(AppIcons.mic, size: 16),
                  label: Text(context.tr('home.voice_retry')),
                ),
              ]

              // ── Listening controls ─────────────────────────────────────────
              else if (isListening) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _stopTimers();
                          _searchNotifier.reset();
                          Navigator.pop(context);
                        },
                        child: Text(context.tr('common.cancel')),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _elapsedSeconds >= 2
                            ? _stopAndProcess
                            : null,
                        icon:  const Icon(AppIcons.stop, size: 16),
                        label: Text(context.tr('home.voice_search_now')),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppConstants.paddingMd),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Waveform ──────────────────────────────────────────────────────────────────

class _Waveform extends StatefulWidget {
  final Color color;
  final bool  isAnimating;

  const _Waveform({required this.color, required this.isAnimating});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const List<double> _heights = [
    8.0, 18.0, 28.0, 36.0, 42.0, 36.0, 28.0, 18.0, 8.0
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.buttonHeightMd,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder:   (_, __) => Row(
          mainAxisAlignment:  MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_heights.length, (i) {
            final phase  = (i / _heights.length) * 2 * math.pi;
            final factor = widget.isAnimating
                ? (0.4 +
                    0.6 *
                        (math.sin(
                                    _ctrl.value * 2 * math.pi + phase) +
                                1) /
                            2)
                : 0.3;
            return Container(
              width:  3,
              height: _heights[i] * factor,
              margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXxs),
              decoration: BoxDecoration(
                color:        widget.color
                    .withValues(alpha: (0.7 + factor * 0.3).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(AppConstants.strengthBarRadius),
              ),
            );
          }),
        ),
      ),
    );
  }
}
