// lib/screens/settings/settings_screen.dart
//
// Point Final layout: AppBar row = back button + "Settings." title beside it
// (same row, no pushed-down in-body headline).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../utils/localization.dart';
import '../../utils/app_theme.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/back_button.dart';
import '../../widgets/feature_error_state.dart';
import '../../widgets/wordmark.dart';
import '../../providers/settings_provider.dart';
import 'widgets/settings_content.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        // The active ThemeData already provides scaffoldBackgroundColor per brightness.
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          // Opaque scaffold colour so scrolling content masks under the title.
          backgroundColor:        Theme.of(context).scaffoldBackgroundColor,
          elevation:              0,
          scrolledUnderElevation: 0,
          centerTitle:            false,
          title: PointFinalTitle(context.tr('settings.title')),
          // Settings is a tab root when opened from the nav bar — only show a
          // back affordance when there is actually a route to pop.
          automaticallyImplyLeading: false,
          leading: context.canPop()
              ? const AppBarBackButton()
              : null,
        ),
        body: switch (state.status) {
          SettingsStatus.error => FeatureErrorState(
              isDark:     isDark,
              errorTitle: context.tr('common.error'),
              message: state.errorMessage != null
                  ? context.tr(state.errorMessage!)
                  : null,
              retryLabel: context.tr('common.retry'),
              onRetry:    () => ref.read(settingsProvider.notifier).retry(),
            ),
          _ => Stack(
              children: [
                SettingsContent(state: state),
                if (state.isSigningOut || state.isDeletingAccount)
                  const _FullScreenOverlay(),
              ],
            ),
        },
      ),
    );
  }
}

class _FullScreenOverlay extends StatelessWidget {
  const _FullScreenOverlay();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:      context.tr('common.loading'),
      liveRegion: true,
      child: Container(
        // overlayScrim35 = Color(0x59000000) — black at 35% opacity.
        color: AppTheme.overlayScrim35,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
