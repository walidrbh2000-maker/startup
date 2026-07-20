// lib/screens/worker_jobs/widgets/tab_empty_state.dart

import 'package:flutter/material.dart';

import '../../../utils/localization.dart';
import '../../../widgets/feature_empty_state.dart';

class TabEmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String titleKey;
  final String subtitleKey;

  const TabEmptyState({
    super.key,
    required this.isDark,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureEmptyState(
      isDark: isDark,
      icon: icon,
      title: context.tr(titleKey),
      subtitle: context.tr(subtitleKey),
    );
  }
}
