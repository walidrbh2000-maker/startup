// lib/screens/worker_jobs/widgets/whatsapp_circle_btn.dart
//
// Circular WhatsApp contact button (launchWhatsApp + busy state + error
// snackbar). One class, sized via [size]: 46 in the FAB row, 40 inline.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/localization.dart';
import '../../../utils/whatsapp_launcher.dart'; // AppTheme.whatsAppGreen + WhatsAppIcon

class WhatsAppCircleBtn extends StatefulWidget {
  final String phone;
  final bool   isDark;
  final bool   disabled;
  final String label;

  /// Diameter of the circle button.
  /// Use 46 for the FAB row (job_detail_fab_row), 40 for the inline row
  /// (job_action_buttons).
  final double size;

  const WhatsAppCircleBtn({
    super.key,
    required this.phone,
    required this.isDark,
    this.disabled = false,
    required this.label,
    this.size = 46,
  });

  @override
  State<WhatsAppCircleBtn> createState() => _WhatsAppCircleBtnState();
}

class _WhatsAppCircleBtnState extends State<WhatsAppCircleBtn> {
  bool _busy = false;

  Future<void> _launch() async {
    if (_busy || widget.disabled) return;
    setState(() => _busy = true);
    try {
      final msg = context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(phone: widget.phone, message: msg);
      if (!ok && mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          context.tr('whatsapp.open_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || _busy;

    final bgColor = widget.isDark
        ? AppTheme.whatsAppDarkSurface
        : Colors.white;

    return Semantics(
      button: true,
      label:  widget.label,
      child: GestureDetector(
        onTap: isDisabled ? null : _launch,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity:  isDisabled ? 0.45 : 1.0,
          child: Container(
            width:  widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color:     bgColor,
              shape:     BoxShape.circle,
              border:    Border.all(
                color: AppTheme.whatsAppGreen.withValues(alpha: 0.55),
                width: 1.2,
              ),
            ),
            child: _busy
                ? Padding(
                    padding: EdgeInsets.all(widget.size * 0.22),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       AppTheme.whatsAppGreen,
                    ),
                  )
                : Center(
                    child: WhatsAppIcon(size: widget.size * 0.52),
                  ),
          ),
        ),
      ),
    );
  }
}
