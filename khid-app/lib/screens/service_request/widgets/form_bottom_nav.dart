// lib/screens/service_request/widgets/form_bottom_nav.dart

import 'package:flutter/material.dart';

import '../../../providers/service_request_form_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/back_button.dart';

// ============================================================================
// FORM BOTTOM NAV
// Back button (steps > 0) + full-width Next / Submit CTA.
// ============================================================================

class FormBottomNav extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final int currentStep;
  final ServiceRequestFormState state;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const FormBottomNav({
    super.key,
    required this.isDark,
    required this.accent,
    required this.currentStep,
    required this.state,
    required this.onBack,
    required this.onNext,
  });

  String _nextLabel(BuildContext context) {
    if (currentStep < 2) return context.tr('common.next');
    return switch (state.submitStatus) {
      SubmitStatus.uploading => context.tr('request_form.uploading_media'),
      SubmitStatus.submitting => context.tr('request_form.submitting'),
      _ => context.tr('request_form.submit_button'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == 2;
    final label = _nextLabel(context);
    final isEnabled = onNext != null && !state.isSubmitting;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkBackground : AppTheme.lightBackground)
            .withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.paddingSm,
        AppConstants.paddingMd,
        AppConstants.paddingSm + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          // Back button — shown only when onBack is provided (i.e. step > 0).
          // useSecondaryColor: de-emphasises the arrow vs the primary CTA.
          // withBorder: matches the visual style of this header-adjacent context.
          if (onBack != null) ...[
            AppBackButton(
              isDark:            isDark,
              withBorder:        true,
              useSecondaryColor: true,
              onPressed:         onBack,
            ),
            const SizedBox(width: AppConstants.spacingSm),
          ],
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              enabled: isEnabled,
              child: GestureDetector(
                onTap: isEnabled ? onNext : null,
                child: AnimatedOpacity(
                  opacity: isEnabled ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    height: AppConstants.buttonHeightMd,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.isSubmitting) ...[
                          SizedBox(
                            width:  AppConstants.spinnerSizeLg,
                            height: AppConstants.spinnerSizeLg,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                        ],
                        Text(
                          label,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (!isLast && !state.isSubmitting) ...[
                          const SizedBox(width: AppConstants.spacingXs),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
