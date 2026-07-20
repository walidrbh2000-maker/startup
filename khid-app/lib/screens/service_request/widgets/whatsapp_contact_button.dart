// lib/screens/service_request/widgets/whatsapp_contact_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/service_request_enhanced_model.dart';
import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/localization.dart';
import '../../../utils/whatsapp_launcher.dart';

// ============================================================================
// WHATSAPP CONTACT BUTTON
// ============================================================================

class WhatsAppContactButton extends ConsumerStatefulWidget {
  final ServiceRequestEnhancedModel request;
  final bool                        isDark;

  const WhatsAppContactButton({
    super.key,
    required this.request,
    required this.isDark,
  });

  @override
  ConsumerState<WhatsAppContactButton> createState() =>
      _WhatsAppContactButtonState();
}

class _WhatsAppContactButtonState
    extends ConsumerState<WhatsAppContactButton> {
  bool _launching = false;

  Future<void> _launch(String phone) async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      final msg = context.tr('whatsapp.contact_message');
      final ok  = await launchWhatsApp(phone: phone, message: msg);
      if (!ok && mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          context.tr('whatsapp.open_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Widget _buildButton({
    required BuildContext context,
    required bool         isDark,
    required String?      phone,
    required bool         isLoading,
  }) {
    return Semantics(
      button:  true,
      label:   context.tr('tracking.contact_worker'),
      enabled: !isLoading && phone != null,
      child: SizedBox(
        width:  double.infinity,
        height: AppConstants.buttonHeightMd,
        child: ElevatedButton(
          onPressed:
              (isLoading || phone == null) ? null : () => _launch(phone),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppTheme.whatsAppDarkSurface
                : Colors.white,
            foregroundColor: AppTheme.whatsAppGreen,
            disabledBackgroundColor: isDark
                ? AppTheme.whatsAppDarkSurface.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.5),
            elevation: 0,
            side: BorderSide(
                color: AppTheme.whatsAppGreen.withValues(alpha: 0.55), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width:  AppConstants.spinnerSizeLg,
                  height: AppConstants.spinnerSizeLg,
                  child:  CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.whatsAppGreen),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WhatsAppIcon(size: 22),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      context.tr('tracking.contact_worker'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.whatsAppGreen
                            : AppTheme.whatsAppDeep,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workerId    = widget.request.workerId!;
    final workerAsync = ref.watch(workerProfileProvider(workerId));

    return workerAsync.when(
      loading: () => _buildButton(
          context: context,
          isDark:  widget.isDark,
          phone:   null,
          isLoading: true),
      error: (_, __) => const SizedBox.shrink(),
      data: (worker) {
        final phone = worker?.phoneNumber ?? '';
        if (phone.trim().isEmpty) return const SizedBox.shrink();
        return _buildButton(
          context:   context,
          isDark:    widget.isDark,
          phone:     phone,
          isLoading: _launching,
        );
      },
    );
  }
}
