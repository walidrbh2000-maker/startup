// lib/screens/auth/widgets/auth_submit_button.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';


class AuthSubmitButton extends StatelessWidget {
  final bool         isLoading;
  final bool         isDark;
  final VoidCallback? onPressed;
  final String       labelKey;

  const AuthSubmitButton({
    super.key,
    required this.isLoading,
    required this.isDark,
    required this.onPressed,
    required this.labelKey,
  });

  bool get _isEnabled => !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button:  true,
      enabled: _isEnabled,
      label:   context.tr(labelKey),
      child: SizedBox(
        height: AppConstants.buttonHeight,
        child: Material(
          color:        _isEnabled ? accent : AppTheme.accentDisabledFill,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: InkWell(
            onTap:        _isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width:  AppConstants.spinnerSizeLg,
                      height: AppConstants.spinnerSizeLg,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        // Spinner uses onPrimary so it stays readable against
                        // the accent-filled button surface in both themes.
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      context.tr(labelKey),
                      style: TextStyle(
                        color: _isEnabled
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onPrimary
                                .withValues(alpha: AppConstants.opacityDisabledColor),
                        fontSize:      AppConstants.buttonFontSize,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
