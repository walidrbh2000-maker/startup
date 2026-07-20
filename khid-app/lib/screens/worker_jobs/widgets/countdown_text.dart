// lib/screens/worker_jobs/widgets/countdown_text.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// COUNTDOWN TEXT
// Owns its own Timer so only this tiny Row rebuilds every second —
// not the parent ListView of request cards.

class CountdownText extends StatefulWidget {
  final DateTime deadline;

  const CountdownText({super.key, required this.deadline});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = widget.deadline.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        _timer?.cancel();
        _timer = null;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(CountdownText old) {
    super.didUpdateWidget(old);
    if (old.deadline != widget.deadline) {
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}min';
    }
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      return const SizedBox.shrink();
    }
    // Warning tone must follow the theme: #FBBF24 on lightBackground is
    // ~1.7:1 — unreadable. Same switch AppTheme.getStatusColor applies.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warning = isDark ? AppTheme.darkWarning : AppTheme.lightWarning;

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingXs),
      child: Row(
        children: [
          Icon(
            AppIcons.timer,
            size: AppConstants.iconSizeXs,
            color: warning,
          ),
          const SizedBox(width: 4),
          Text(
            '${context.tr('worker_browse.time_left')}: ${_format(remaining)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: warning,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
