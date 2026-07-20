// lib/screens/auth/widgets/avatar_picker_widget.dart
//
// Avatar selection: emoji options + camera/gallery button.
// Selected state: accent ring + checkmark overlay.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sheet_chrome.dart';
import '../../../utils/localization.dart';

// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kEmojiAvatars = [
  '👤', '🧑', '👨', '👩', '🧔', '👱',
  '👷', '👷‍♀️', '🧑‍🔧', '👨‍🔧', '👩‍🔧', '🧑‍🌾',
];

// ─────────────────────────────────────────────────────────────────────────────

class AvatarPickerWidget extends StatefulWidget {
  /// Called when user selects a local image path (camera/gallery).
  final ValueChanged<String?> onImagePathSelected;

  /// Called when user picks an emoji avatar.
  final ValueChanged<String?> onEmojiSelected;

  /// Currently selected image path (local file).
  final String? selectedImagePath;

  /// Currently selected emoji.
  final String? selectedEmoji;

  const AvatarPickerWidget({
    super.key,
    required this.onImagePathSelected,
    required this.onEmojiSelected,
    this.selectedImagePath,
    this.selectedEmoji,
  });

  @override
  State<AvatarPickerWidget> createState() => _AvatarPickerWidgetState();
}

class _AvatarPickerWidgetState extends State<AvatarPickerWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final file = await _picker.pickImage(
        source:       source,
        maxWidth:     AppConstants.avatarMaxDimensionPx,
        maxHeight:    AppConstants.avatarMaxDimensionPx,
        imageQuality: AppConstants.avatarImageQuality,
      );
      if (file != null && mounted) {
        widget.onEmojiSelected(null); // Clear emoji
        widget.onImagePathSelected(file.path);
      }
    } catch (_) {
      // Permission denied or cancelled
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _onEmojiTap(String emoji) {
    HapticFeedback.selectionClick();
    widget.onImagePathSelected(null); // Clear photo
    widget.onEmojiSelected(
      widget.selectedEmoji == emoji ? null : emoji,
    );
  }

  void _showSourceSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: false,
      backgroundColor:    Colors.transparent,
      builder: (_) => _SourceSheet(
        isDark:   Theme.of(context).brightness == Brightness.dark,
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Column(
      children: [
        // Large avatar preview
        _AvatarPreview(
          imagePath:    widget.selectedImagePath,
          emoji:        widget.selectedEmoji,
          isDark:       isDark,
          isProcessing: _picking,
          onTap:        _showSourceSheet,
        ),

        const SizedBox(height: AppConstants.spacingMd),

        // Emoji grid — wraps to multiple rows as the set grows.
        Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 12,
          children: [
            ..._kEmojiAvatars.map((emoji) {
              final isSelected = widget.selectedEmoji == emoji &&
                  widget.selectedImagePath == null;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Semantics(
                  button:   true,
                  selected: isSelected,
                  label:    'Avatar emoji $emoji',
                  child: GestureDetector(
                    onTap: () => _onEmojiTap(emoji),
                    child: AnimatedContainer(
                      duration: AppConstants.animDurationMicro,
                      width:  52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? accent.withValues(alpha: 0.15)
                            : (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          width: isSelected
                              ? AppConstants.borderWidthSelected
                              : AppConstants.borderWidthDefault,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Camera button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Semantics(
                button: true,
                label:  context.tr('request_form.camera'),
                child: GestureDetector(
                  onTap: _showSourceSheet,
                  child: Container(
                    width:  52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceVariant,
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        width: AppConstants.borderWidthDefault,
                      ),
                    ),
                    child: Icon(
                      AppIcons.camera,
                      size:  AppConstants.iconSizeSm,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar preview circle (96dp)
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPreview extends StatelessWidget {
  final String?  imagePath;
  final String?  emoji;
  final bool     isDark;
  final bool     isProcessing;
  final VoidCallback onTap;

  const _AvatarPreview({
    required this.imagePath,
    required this.emoji,
    required this.isDark,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button: true,
      label:  context.tr('profile.change_photo'),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main circle
            Container(
              width:  AppConstants.avatarSizeXl,
              height: AppConstants.avatarSizeXl,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  accent.withValues(alpha: 0.10),
                border: Border.all(color: accent.withValues(alpha: 0.40), width: 2),
              ),
              child: ClipOval(
                child: isProcessing
                    ? Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : imagePath != null
                        ? Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _Fallback(accent: accent),
                          )
                        : emoji != null
                            ? Center(
                                child: Text(
                                  emoji!,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              )
                            : _Fallback(accent: accent),
              ),
            ),

            // Camera badge
            Positioned(
              bottom: 0,
              right:  0,
              child: Container(
                width:  30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:  accent,
                  border: Border.all(
                    color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size:  14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final Color accent;
  const _Fallback({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size:  48,
        color: accent.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SourceSheet extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SourceSheet({
    required this.isDark,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.paddingMd,
        AppConstants.paddingLg,
        MediaQuery.of(context).padding.bottom + AppConstants.paddingLg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHandle(isDark: isDark),
          const SizedBox(height: AppConstants.paddingMd),
          _SourceTile(
            icon:    AppIcons.camera,
            labelKey: 'request_form.camera',
            isDark:  isDark,
            onTap:   onCamera,
          ),
          _SourceTile(
            icon:    AppIcons.gallery,
            labelKey: 'request_form.gallery',
            isDark:  isDark,
            onTap:   onGallery,
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String   labelKey;
  final bool     isDark;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.labelKey,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  context.tr(labelKey),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height:  AppConstants.tileHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size:  AppConstants.iconSizeSm,
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Text(
                context.tr(labelKey),
                style: TextStyle(
                  fontSize: AppConstants.fontSizeMd,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
