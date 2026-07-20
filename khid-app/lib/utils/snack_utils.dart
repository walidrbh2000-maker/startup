// lib/utils/snack_utils.dart

import 'package:flutter/material.dart';

import 'error_handler.dart';

/// Themed snackbar utility shared across all auth screens.
///
/// Thin alias over [ErrorHandler] so auth snackbars share the single
/// app-wide style (floating, semantic color + icon).
///
/// Usage:
///   showAuthSnackBar(context, context.tr('login.reset_email_sent'));
///   showAuthSnackBar(context, context.tr(errorKey), isError: true);
void showAuthSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  isError
      ? ErrorHandler.showErrorSnackBar(context, message)
      : ErrorHandler.showInfoSnackBar(context, message);
}
