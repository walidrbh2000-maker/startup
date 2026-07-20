// lib/screens/service_request/widgets/step_describe.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'media_picker_area.dart';
import 'suggestion_chip_row.dart';

// ============================================================================
// STEP 2 — DESCRIBE THE ISSUE
// Description field + suggestion chips + media upload.
// Pure UI: all mutations delegate to callbacks.
// ============================================================================

class StepDescribe extends StatelessWidget {
  final TextEditingController descriptionController;
  final List<File> mediaFiles;
  final bool isDark;
  final Color accentColor;
  final int charCount;
  /// The service type selected in step 1 — drives contextual suggestion chips.
  final String? serviceType;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onPickVideo;
  final ValueChanged<int> onRemoveMedia;

  static const int _maxChars = 500;

  const StepDescribe({
    super.key,
    required this.descriptionController,
    required this.mediaFiles,
    required this.isDark,
    required this.accentColor,
    required this.charCount,
    this.serviceType,
    required this.onDescriptionChanged,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickVideo,
    required this.onRemoveMedia,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.spacingMd,
        AppConstants.paddingMd,
        AppConstants.spacingXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Headline ──────────────────────────────────────────────
          Text(
            context.tr('request_form.section_describe'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            context.tr('request_form.description_subtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Description card ──────────────────────────────────────
          _DescriptionCard(
            controller: descriptionController,
            isDark: isDark,
            accentColor: accentColor,
            charCount: charCount,
            maxChars: _maxChars,
            onChanged: onDescriptionChanged,
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // ── Quick-fill chips ──────────────────────────────────────
          SuggestionChipRow(
            serviceType: serviceType,
            isDark: isDark,
            accentColor: accentColor,
            onChipTap: (text) {
              final current = descriptionController.text;
              final appended =
                  current.isEmpty ? text : '$current $text';
              descriptionController.text = appended;
              descriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: appended.length),
              );
              onDescriptionChanged(appended);
            },
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── Media header ──────────────────────────────────────────
          Row(
            children: [
              Text(
                context.tr('request_form.section_media'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSm,
                  vertical: AppConstants.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppTheme.darkSurfaceVariant
                          : AppTheme.lightSurfaceVariant)
                      .withValues(alpha: 0.7),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  context.tr('request_form.optional_tag'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Media area ────────────────────────────────────────────
          MediaPickerArea(
            mediaFiles: mediaFiles,
            isDark: isDark,
            accentColor: accentColor,
            onPickCamera: onPickCamera,
            onPickGallery: onPickGallery,
            onPickVideo: onPickVideo,
            onRemoveMedia: onRemoveMedia,
          ),

          const SizedBox(height: AppConstants.spacingXs + 2),
          Text(
            context.tr('request_form.media_hint'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DESCRIPTION CARD
// Extracted private widget — field + char-count footer. < 90 lines.
// ============================================================================

class _DescriptionCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color accentColor;
  final int charCount;
  final int maxChars;
  final ValueChanged<String> onChanged;

  const _DescriptionCard({
    required this.controller,
    required this.isDark,
    required this.accentColor,
    required this.charCount,
    required this.maxChars,
    required this.onChanged,
  });

  bool get _isValid => charCount >= 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.6)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: _isValid
              ? accentColor.withValues(alpha: 0.45)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input area
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMd,
              AppConstants.paddingMd,
              AppConstants.paddingMd,
              AppConstants.paddingSm,
            ),
            child: Semantics(
              label: context.tr('request_form.description_label'),
              textField: true,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: 7,
                minLines: 5,
                maxLength: maxChars,
                buildCounter: (_, {required currentLength,
                        required isFocused, maxLength}) =>
                    null,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: context.tr('request_form.description_hint'),
                  hintStyle:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          // Footer with status + counter
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMd,
              vertical: AppConstants.spacingSm + 2,
            ),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppConstants.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isValid
                      ? Icons.check_circle_rounded
                      : Icons.edit_note_rounded,
                  size: 14,
                  color: _isValid
                      ? (isDark ? AppTheme.darkAccentText : accentColor)
                      : (isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText),
                ),
                const SizedBox(width: 5),
                Text(
                  _isValid
                      ? context.tr('request_form.description_good')
                      : context.tr('request_form.description_hint_short'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _isValid
                            ? (isDark ? AppTheme.darkAccentText : accentColor)
                            : (isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText),
                      ),
                ),
                const Spacer(),
                Text(
                  '$charCount / $maxChars',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
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
