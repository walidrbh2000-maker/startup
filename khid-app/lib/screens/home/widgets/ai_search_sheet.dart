// lib/screens/home/widgets/ai_search_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_search_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/sheet_chrome.dart';
import 'ai_example_chips.dart';
import 'search_result_card.dart';

class AiSearchSheet extends ConsumerStatefulWidget {
  const AiSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const AiSearchSheet(),
    );
  }

  @override
  ConsumerState<AiSearchSheet> createState() => _AiSearchSheetState();
}

class _AiSearchSheetState extends ConsumerState<AiSearchSheet> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    ref.read(homeSearchControllerProvider.notifier).submitSearch(text);
  }

  void _reset() {
    ref.read(homeSearchControllerProvider.notifier).reset();
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final onPrimary   = Theme.of(context).colorScheme.onPrimary;
    final searchState = ref.watch(homeSearchControllerProvider);
    final isLoading   = searchState.isLoading;
    final hasResult   = searchState.hasResults;
    final hasError    = searchState.hasError;
    final intent      = searchState.lastIntent;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBackground
              : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusXxl)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppConstants.spacingSm),
              const SheetHandle(),
              const SizedBox(height: AppConstants.spacingMd),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLg),
                child: Row(
                  children: [
                    Container(
                      width:  AppConstants.iconContainerSm,
                      height: AppConstants.iconContainerSm,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                      child: Center(
                        child: Icon(AppIcons.ai, size: 14, color: onPrimary),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        context.tr('home.ai_search_title'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SheetCloseButton(
                      semanticsLabel: context.tr('common.close'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              if (hasResult && intent != null && !isLoading) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLg),
                  child: SearchResultCard(
                      intent: intent, isDark: isDark, showTopLabel: true),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLg),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reset,
                          child: Text(context.tr('common.edit')),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(homeSearchControllerProvider.notifier)
                                .applyToMap();
                            Navigator.pop(context);
                          },
                          child: Text(
                              context.tr('home.ai_search_see_workers')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLg),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLg),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.lightBorder,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller:   _ctrl,
                      focusNode:    _focus,
                      autofocus:    true,
                      maxLines:     4,
                      minLines:     3,
                      enabled:      !isLoading,
                      // height 1.5: multi-line input wants looser leading than the 1.6 default.
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:  context.tr('home.ai_search_hint'),
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                          height: 1.5,
                        ),
                        border:         InputBorder.none,
                        contentPadding:
                            const EdgeInsets.all(AppConstants.paddingMd),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXs),

                if (hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLg),
                    child: Text(
                      context.tr('home.search_error'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkError
                            : AppTheme.lightError,
                      ),
                    ),
                  ),

                const SizedBox(height: AppConstants.spacingXs),

                AiExampleChips(
                  isDark: isDark,
                  onTap: (text) {
                    _ctrl.text = text;
                    _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: text.length));
                  },
                ),

                const SizedBox(height: AppConstants.spacingMd),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLg),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? SizedBox(
                            width:  AppConstants.iconSizeSm,
                            height: AppConstants.iconSizeSm,
                            child:  CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(AppIcons.ai, size: 16),
                              const SizedBox(width: AppConstants.spacingSm),
                              Text(context.tr('home.ai_search_submit')),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
