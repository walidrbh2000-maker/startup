// lib/widgets/app_user_avatar.dart

import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/media_path_helper.dart';

class AppUserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String  name;
  final double  radius;
  final Color?  borderColor;
  final double  borderWidth;

  const AppUserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius      = 36,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  String get _initials {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  int get _cacheSize => (radius * 2 * 3).ceil();

  @override
  Widget build(BuildContext context) {
    final ringColor = borderColor ?? Colors.white.withValues(alpha: 0.40);
    final size      = radius * 2;

    // Emoji avatar (persisted as `emoji:X`) → render the glyph, no network call.
    final emojiChar = MediaPathHelper.emoji(imageUrl);

    // Convertit storedPath ou ancienne URL en URL proxy complète
    final displayUrl = (emojiChar == null && imageUrl != null && imageUrl!.isNotEmpty)
        ? MediaPathHelper.toUrl(imageUrl, apiBaseUrl: AppConfig.apiBaseUrl)
        : null;

    return Semantics(
      label: name.trim().isNotEmpty ? name.trim() : _initials,
      image: true,
      child: Container(
        width:  size,
        height: size,
        decoration: BoxDecoration(
          shape:  BoxShape.circle,
          border: Border.all(color: ringColor, width: borderWidth),
        ),
        child: ClipOval(
          child: emojiChar != null
              ? Container(
                  color: Colors.white.withValues(alpha: 0.20),
                  alignment: Alignment.center,
                  child: Text(emojiChar, style: TextStyle(fontSize: radius)),
                )
              : displayUrl != null && displayUrl.isNotEmpty
              ? Image.network(
                  displayUrl,
                  width:       size,
                  height:      size,
                  fit:         BoxFit.cover,
                  cacheWidth:  _cacheSize,
                  cacheHeight: _cacheSize,
                  loadingBuilder: (_, child, progress) =>
                      progress == null
                          ? child
                          : _InitialsFallback(initials: _initials, radius: radius),
                  errorBuilder: (_, __, ___) =>
                      _InitialsFallback(initials: _initials, radius: radius),
                )
              : _InitialsFallback(initials: _initials, radius: radius),
        ),
      ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final String initials;
  final double radius;

  const _InitialsFallback({
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color:     isDark
          ? Colors.white.withValues(alpha: 0.20)
          : Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize:   radius * 0.74,
          fontWeight: FontWeight.w700,
          color: isDark
              ? Colors.white
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
