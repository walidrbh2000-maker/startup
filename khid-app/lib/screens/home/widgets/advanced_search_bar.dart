// lib/screens/home/widgets/advanced_search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_controller.dart';
import '../../../providers/home_search_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/profession_resolver.dart';
import '../../../widgets/search_bar.dart';
import 'ai_search_sheet.dart';
import 'image_search_sheet.dart';
import 'voice_search_sheet.dart';

const double _kAiBtnHeight = 32.0;
const double _kAiIconBadgeSize = 12.0;

class AdvancedSearchBar extends ConsumerStatefulWidget {
  const AdvancedSearchBar({super.key});

  @override
  ConsumerState<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends ConsumerState<AdvancedSearchBar> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) => setState(() {});

  void _onSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    HapticFeedback.lightImpact();
    _focus.unfocus();

    final profession = ProfessionResolver.resolve(trimmed);

    if (profession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('home.search_no_match_hint'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  AiSearchSheet.show(context);
                },
                child: Text(
                  context.tr('home.ai_search_label'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurface
                  : AppTheme.lightText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          margin: const EdgeInsets.all(AppConstants.paddingMd),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final homeNotifier = ref.read(homeControllerProvider.notifier);
    homeNotifier.setServiceFilter(profession);
    homeNotifier.enterMapFullscreen();
  }

  void _openAiSearch() {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    AiSearchSheet.show(context);
  }

  void _openVoice() {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    VoiceSearchSheet.show(context);
  }

  void _openCamera() {
    HapticFeedback.selectionClick();
    _focus.unfocus();
    ImageSearchSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isMapFullscreen = ref.watch(
      homeControllerProvider.select((s) => s.isMapFullscreen),
    );

    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    if (isMapFullscreen) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Search bar (camera + voice via AppSearchBar) ───────────────
          AppSearchBar(
            controller:   _ctrl,
            focusNode:    _focus,
            hintText:     context.tr('home.search_placeholder'),
            isDark:       isDark,
            onChanged: (v) {
              _onTextChanged(v);
              // When cleared via internal button, also reset the search state
              // and unfocus — mirrors the previous _onClear() behaviour.
              if (v.isEmpty) {
                _focus.unfocus();
                ref.read(homeSearchControllerProvider.notifier).reset();
              }
            },
            onSubmitted:  _onSubmitted,
            onCameraTap:  _openCamera,
            onVoiceTap:   _openVoice,
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // ── AI search pill ─────────────────────────────────────────────
          SizedBox(
            height: AppConstants.buttonHeightMd,
            width:  double.infinity,
            child: Center(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  label:  context.tr('home.ai_search_label'),
                  button: true,
                  child: GestureDetector(
                    onTap: _openAiSearch,
                    child: Container(
                      height: _kAiBtnHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMd,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusCircle),
                        border: Border.all(
                          color: accent.withValues(alpha: isDark ? 0.30 : 0.25),
                          width: 0.5,
                        ),
                        color: accent.withValues(alpha: isDark ? 0.08 : 0.06),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width:  20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                            child: Center(
                              child: Icon(
                                AppIcons.ai,
                                size:  _kAiIconBadgeSize,
                                color: onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          Text(
                            context.tr('home.ai_search_label'),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.darkAccentText : accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
