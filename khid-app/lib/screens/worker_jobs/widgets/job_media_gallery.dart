// lib/screens/worker_jobs/widgets/job_media_gallery.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../utils/app_config.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/media_path_helper.dart';
import 'job_media_viewer.dart';

class JobMediaGallery extends StatelessWidget {
  final List<String> urls;
  final bool isDark;
  final Color accentColor;

  const JobMediaGallery({
    super.key,
    required this.urls,
    required this.isDark,
    required this.accentColor,
  });

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('video');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingMd),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: AppConstants.spacingSm),
          itemBuilder: (context, i) {
            final storedPath = urls[i];
            // Convertit storedPath ou ancienne URL en URL proxy complète
            final displayUrl = MediaPathHelper.toUrl(
              storedPath,
              apiBaseUrl: AppConfig.apiBaseUrl,
            );

            return Semantics(
              button: true,
              label: context
                  .tr('worker_jobs.media_item_label')
                  .replaceAll('{n}', '${i + 1}'),
              child: GestureDetector(
                onTap: () => JobMediaViewer.show(
                  context,
                  mediaUrls: urls,
                  initialIndex: i,
                ),
                child: Hero(
                  tag: 'media_${storedPath}_$i',
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                    child: Stack(
                      children: [
                        if (_isVideo(storedPath))
                          Container(
                            width: 100,
                            height: 100,
                            color: isDark
                                ? AppTheme.darkSurfaceVariant
                                : AppTheme.lightSurfaceVariant,
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText,
                              size: 40,
                            ),
                          )
                        else
                          CachedNetworkImage(
                            imageUrl: displayUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 100,
                              height: 100,
                              color: isDark
                                  ? AppTheme.darkSurfaceVariant
                                  : AppTheme.lightSurfaceVariant,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: isDark
                                  ? AppTheme.darkSurfaceVariant
                                  : AppTheme.lightSurfaceVariant,
                              child: Icon(Icons.broken_image_rounded,
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText),
                            ),
                          ),
                        // Number badge
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
