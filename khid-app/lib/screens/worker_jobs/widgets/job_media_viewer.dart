// lib/screens/worker_jobs/widgets/job_media_viewer.dart
// [MEDIA FIX]: Les URLs dans mediaUrls sont des storedPaths ou anciennes URLs.
// On les convertit via MediaPathHelper.toUrl() avant CachedNetworkImage.
// Le tag Hero utilise le storedPath original pour cohérence avec job_media_gallery.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../utils/app_config.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/media_path_helper.dart';
import 'job_media_top_bar.dart';
import 'job_media_nav_arrow.dart';
import 'job_media_dot_indicators.dart';
import 'job_video_placeholder.dart';

class JobMediaViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int          initialIndex;

  const JobMediaViewer({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> mediaUrls,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque:           false,
        barrierColor:     Colors.black87,
        pageBuilder: (_, __, ___) => JobMediaViewer(
          mediaUrls:    mediaUrls,
          initialIndex: initialIndex,
        ),
        transitionDuration: AppConstants.animDurationShort,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child:   child,
        ),
      ),
    );
  }

  @override
  State<JobMediaViewer> createState() => _JobMediaViewerState();
}

class _JobMediaViewerState extends State<JobMediaViewer>
    with SingleTickerProviderStateMixin {
  late PageController        _pageCtrl;
  late int                   _currentIndex;
  bool                       _showUI = true;
  late AnimationController   _uiCtrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl     = PageController(initialPage: widget.initialIndex);
    _uiCtrl       = AnimationController(
      vsync:    this,
      duration: AppConstants.animDurationMicro,
      value:    1.0,
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _uiCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) {
      _uiCtrl.forward();
    } else {
      _uiCtrl.reverse();
    }
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.avi') ||
        lower.contains('.mkv') ||
        lower.contains('video');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Page view
            PageView.builder(
              controller:  _pageCtrl,
              itemCount:   widget.mediaUrls.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                final storedPath = widget.mediaUrls[i];

                if (_isVideo(storedPath)) {
                  return JobVideoPlaceholder(url: storedPath, isDark: true);
                }

                // Convertit storedPath ou ancienne URL en URL proxy complète
                final displayUrl = MediaPathHelper.toUrl(
                  storedPath,
                  apiBaseUrl: AppConfig.apiBaseUrl,
                );

                return InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 4.0,
                  child: Hero(
                    // Tag cohérent avec job_media_gallery (utilise le storedPath)
                    tag:   'media_${storedPath}_$i',
                    child: CachedNetworkImage(
                      imageUrl: displayUrl,
                      fit:      BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color:       Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_rounded,
                                color: Colors.white38, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('worker_jobs.media_load_error'),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Overlay UI
            FadeTransition(
              opacity: _uiCtrl,
              child: IgnorePointer(
                ignoring: !_showUI,
                child: Column(
                  children: [
                    JobMediaTopBar(
                      currentIndex: _currentIndex,
                      total:        widget.mediaUrls.length,
                      onClose:      () => Navigator.pop(context),
                    ),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMd),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentIndex > 0)
                            JobMediaNavArrow(
                              icon:  Icons.chevron_left_rounded,
                              onTap: () {
                                _pageCtrl.previousPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve:    Curves.easeOutCubic,
                                );
                              },
                            )
                          else
                            const SizedBox(width: 48),
                          if (_currentIndex < widget.mediaUrls.length - 1)
                            JobMediaNavArrow(
                              icon:  Icons.chevron_right_rounded,
                              onTap: () {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve:    Curves.easeOutCubic,
                                );
                              },
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    if (widget.mediaUrls.length > 1)
                      JobMediaDotIndicators(
                        count:   widget.mediaUrls.length,
                        current: _currentIndex,
                      ),

                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
