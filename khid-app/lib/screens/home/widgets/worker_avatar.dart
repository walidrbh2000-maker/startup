// lib/screens/home/widgets/worker_avatar.dart

import 'package:flutter/material.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_config.dart';
import '../../../utils/constants.dart';
import '../../../utils/media_path_helper.dart';

// ============================================================================
// WORKER AVATAR
// ============================================================================

const double _kAvatarSize = 64.0;

class WorkerAvatar extends StatelessWidget {
  final WorkerModel worker;
  final Color       color;

  const WorkerAvatar({super.key, required this.worker, required this.color});

  @override
  Widget build(BuildContext context) {
    // Emoji avatar (`emoji:X`) → render the glyph instead of a network image.
    final emojiChar = MediaPathHelper.emoji(worker.profileImageUrl);

    // storedPath ("bucket/uid/file.jpg") or legacy URL → full proxy URL.
    final displayUrl = (emojiChar == null && worker.profileImageUrl != null)
        ? MediaPathHelper.toUrl(
            worker.profileImageUrl,
            apiBaseUrl: AppConfig.apiBaseUrl,
          )
        : null;

    return Container(
      width:  _kAvatarSize,
      height: _kAvatarSize,
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        color:  color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 2),
      ),
      child: emojiChar != null
          ? Center(child: Text(emojiChar, style: const TextStyle(fontSize: _kAvatarSize * 0.5)))
          : displayUrl != null && displayUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                displayUrl,
                fit:          BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  AppIcons.person,
                  color: color,
                  size:  AppConstants.iconSizeMd,
                ),
              ),
            )
          : Icon(AppIcons.person, color: color, size: AppConstants.iconSizeMd),
    );
  }
}
