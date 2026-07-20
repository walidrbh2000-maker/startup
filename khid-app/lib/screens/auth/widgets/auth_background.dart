// lib/screens/auth/widgets/auth_background.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final bool isDark;

  const AuthBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppTheme.darkAuthHeroTop, AppTheme.darkBackground]
                : [AppTheme.lightSurface, AppTheme.lightBackground],
          ),
        ),
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -1.2),
                radius: 1.0,
                colors: [
                  isDark ? AppTheme.darkAccentHalo : AppTheme.lightAccentHalo,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
