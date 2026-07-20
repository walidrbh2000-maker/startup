// lib/screens/service_request/widgets/request_form_stepper.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// REQUEST FORM STEPPER
// Numbered, animated 3-step indicator replacing the old flat progress bar.
// Done   → filled accent circle + checkmark
// Active → white/surface circle + accent border + step number
// Future → muted surface circle + muted number
// ============================================================================

class RequestFormStepper extends StatelessWidget {
  final int currentStep;
  final Color accent;
  final bool isDark;

  const RequestFormStepper({
    super.key,
    required this.currentStep,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr('request_form.step_service_short'),
      context.tr('request_form.step_describe_short'),
      context.tr('request_form.step_confirm_short'),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.spacingMd,
        AppConstants.paddingMd,
        AppConstants.spacingSm,
      ),
      child: Row(
        children: List.generate(5, (i) {
          if (i.isEven) {
            final stepIndex = i ~/ 2;
            return _StepCircle(
              index: stepIndex,
              currentStep: currentStep,
              accent: accent,
              isDark: isDark,
              label: labels[stepIndex],
            );
          } else {
            final connectorIndex = i ~/ 2;
            return _StepConnector(
              done: connectorIndex < currentStep,
              accent: accent,
              isDark: isDark,
            );
          }
        }),
      ),
    );
  }
}

// ── Step circle ───────────────────────────────────────────────────────────────

class _StepCircle extends StatelessWidget {
  final int index;
  final int currentStep;
  final Color accent;
  final bool isDark;
  final String label;

  const _StepCircle({
    required this.index,
    required this.currentStep,
    required this.accent,
    required this.isDark,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentStep;
    final isCurrent = index == currentStep;

    final circleBg = isDone
        ? accent
        : isCurrent
            ? (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
            : (isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant);

    final borderColor = (isDone || isCurrent) ? accent : Colors.transparent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppConstants.animDurationShort,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeXxs,
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? accent
                          : (isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingXxs),
        Text(
          label,
          style: TextStyle(
            fontSize: AppConstants.fontSizeXxs,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent
                ? accent
                : isDone
                    ? accent.withValues(alpha: 0.65)
                    : (isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText),
          ),
        ),
      ],
    );
  }
}

// ── Step connector ────────────────────────────────────────────────────────────

class _StepConnector extends StatelessWidget {
  final bool done;
  final Color accent;
  final bool isDark;

  const _StepConnector({
    required this.done,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spacingMdLg),
        child: AnimatedContainer(
          duration: AppConstants.animDurationShort,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXs),
          decoration: BoxDecoration(
            color: done
                ? accent
                : (isDark
                    ? AppTheme.darkSurfaceVariant
                    : AppTheme.lightSurfaceVariant),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
