// lib/screens/service_request/widgets/media_picker_area.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../widgets/sheet_chrome.dart';
import '../../../utils/localization.dart';

class MediaPickerArea extends StatelessWidget {
  final List<File>      mediaFiles;
  final bool            isDark;
  final Color           accentColor;
  final VoidCallback    onPickCamera;
  final VoidCallback    onPickGallery;
  final VoidCallback    onPickVideo;
  final ValueChanged<int> onRemoveMedia;

  static const int _maxFiles = 5;

  const MediaPickerArea({
    super.key,
    required this.mediaFiles,
    required this.isDark,
    required this.accentColor,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onPickVideo,
    required this.onRemoveMedia,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaFiles.isNotEmpty) {
      return _ThumbnailStrip(
        files:      mediaFiles,
        isDark:     isDark,
        accentColor: accentColor,
        canAddMore: mediaFiles.length < _maxFiles,
        onRemove:   onRemoveMedia,
        onAddMore:  () => _showPickerSheet(context),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark
              ? AppTheme.darkCardBorderOverlay
              : AppTheme.lightCardBorderOverlay,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PickerButton(
              icon:  AppIcons.camera,
              label: context.tr('request_form.camera'),
              isDark: isDark,
              onTap:  onPickCamera,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: _PickerButton(
              icon:  AppIcons.image,
              label: context.tr('request_form.gallery'),
              isDark: isDark,
              onTap:  onPickGallery,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: _PickerButton(
              icon:  AppIcons.videocam,
              label: context.tr('request_form.video'),
              isDark: isDark,
              onTap:  onPickVideo,
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MediaPickerSheet(
        isDark:      isDark,
        accentColor: accentColor,
        onGallery: () {
          Navigator.pop(context);
          onPickGallery();
        },
        onCamera: () {
          Navigator.pop(context);
          onPickCamera();
        },
        onVideo: () {
          Navigator.pop(context);
          onPickVideo();
        },
      ),
    );
  }
}

// ── Empty state — three picker buttons ───────────────────────────────────────

class _PickerButton extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final bool      isDark;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppConstants.iconSizeLg2,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size:  22,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
              ),
              const SizedBox(height: AppConstants.spacingXs),
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
        ),
      ),
    );
  }
}

// ── Horizontal thumbnail strip ────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  final List<File>      files;
  final bool            isDark;
  final Color           accentColor;
  final bool            canAddMore;
  final ValueChanged<int> onRemove;
  final VoidCallback    onAddMore;

  const _ThumbnailStrip({
    required this.files,
    required this.isDark,
    required this.accentColor,
    required this.canAddMore,
    required this.onRemove,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:       files.length + (canAddMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppConstants.spacingSm),
        itemBuilder: (context, i) {
          if (i == files.length) {
            return _AddMoreTile(accentColor: accentColor, onTap: onAddMore);
          }
          return _MediaThumbnail(
            file:     files[i],
            onRemove: () => onRemove(i),
            removeLabel: context.tr('request_form.remove_media'),
          );
        },
      ),
    );
  }
}

// ── Single media thumbnail ────────────────────────────────────────────────────

class _MediaThumbnail extends StatelessWidget {
  final File   file;
  final String removeLabel;
  final VoidCallback onRemove;

  const _MediaThumbnail({
    required this.file,
    required this.removeLabel,
    required this.onRemove,
  });

  bool get _isVideo {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          child: _isVideo
              ? Container(
                  width:  88,
                  height: 88,
                  color:  AppTheme.darkSurface,
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white70,
                    size:  AppConstants.iconSizeLg,
                  ),
                )
              : Image.file(
                  file,
                  width:  88,
                  height: 88,
                  fit:    BoxFit.cover,
                  cacheWidth:  264,
                  cacheHeight: 264,
                ),
        ),
        Positioned(
          top:   AppConstants.spacingXs,
          right: AppConstants.spacingXs,
          child: Semantics(
            button: true,
            label:  removeLabel,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width:  20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size:  12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Add-more tile ─────────────────────────────────────────────────────────────

class _AddMoreTile extends StatelessWidget {
  final Color        accentColor;
  final VoidCallback onTap;

  const _AddMoreTile({required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  88,
        height: 88,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: Icon(AppIcons.add, color: accentColor, size: 28),
      ),
    );
  }
}

// ── Bottom sheet picker ───────────────────────────────────────────────────────

class _MediaPickerSheet extends StatelessWidget {
  final bool         isDark;
  final Color        accentColor;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onVideo;

  const _MediaPickerSheet({
    required this.isDark,
    required this.accentColor,
    required this.onGallery,
    required this.onCamera,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLg,
        AppConstants.paddingLg,
        AppConstants.paddingLg,
        AppConstants.paddingLg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.97)
            : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXxl),
        ),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHandle(isDark: isDark),
          const SizedBox(height: AppConstants.spacingLg),
          _SheetRow(
            icon:   AppIcons.camera,
            label:  context.tr('request_form.camera'),
            isDark: isDark,
            onTap:  onCamera,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _SheetRow(
            icon:   AppIcons.image,
            label:  context.tr('request_form.gallery'),
            isDark: isDark,
            onTap:  onGallery,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _SheetRow(
            icon:   AppIcons.videocam,
            label:  context.tr('request_form.video'),
            isDark: isDark,
            onTap:  onVideo,
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         isDark;
  final VoidCallback onTap;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppConstants.buttonHeightMd,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppConstants.paddingMd,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size:  AppConstants.iconSizeSm,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText),
              const SizedBox(width: AppConstants.spacingMd),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
