// lib/utils/error_handler.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/service_request_service.dart';
import '../services/worker_bid_service.dart';
import 'app_theme.dart';
import 'logger.dart';

/// Maps any thrown error to a translation key under `errors.*`.
///
/// The UI must never render raw exception text (`e.toString()` /
/// `e.message`) — controllers store the key returned here and screens
/// display `context.tr(key)`.
String errorKeyFor(Object? error) {
  if (error is TimeoutException) return 'errors.connection';

  String? code;
  if (error is ApiServiceException) {
    code = error.code;
  } else if (error is WorkerBidServiceException) {
    code = error.code;
  } else if (error is ServiceRequestServiceException) {
    code = error.code;
  }

  switch (code) {
    case 'NETWORK_ERROR':
      return 'errors.network';
    case 'UNAUTHENTICATED':
    case 'AUTH_MISMATCH':
    case 'PERMISSION_DENIED':
      return 'errors.unauthorized';
    case 'NOT_FOUND':
    case 'REQUEST_NOT_FOUND':
      return 'errors.not_found';
    case 'ALREADY_EXISTS':
    case 'DUPLICATE_BID':
      return 'errors.duplicate_bid';
    case 'RESOURCE_EXHAUSTED':
    case 'RATE_LIMIT':
      return 'errors.too_many_requests';
    // Bid-quota gate (pack model): distinct messages drive distinct CTAs.
    case 'SUBSCRIPTION_REQUIRED':
      return 'errors.subscription_required';
    case 'BID_NOT_INCLUDED':
      return 'errors.bid_not_included';
    case 'BID_QUOTA_EXHAUSTED':
      return 'errors.bid_quota_exhausted';
    case 'DOCS_REQUIRED_FOR_B2B':
      return 'errors.docs_required_b2b';
  }
  if (code != null) {
    if (code.startsWith('INVALID_') ||
        code.endsWith('_TOO_SHORT') ||
        code.endsWith('_TOO_LONG') ||
        code.endsWith('_TOO_HIGH')) {
      return 'errors.validation';
    }
    if (code.endsWith('_TIMEOUT')) return 'errors.connection';
  }
  return 'errors.generic';
}

/// Error handler with logging and themed UI.
///
/// One snackbar style app-wide: floating, rounded, semantic color + icon.
/// Pass already-translated text — map exceptions with [errorKeyFor] first.
class ErrorHandler {
  ErrorHandler._();

  static void showErrorSnackBar(
    BuildContext context,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    AppLogger.error(message, error, stackTrace);
    _show(context, errorSnackBar(message, isDark: _isDark(context)));
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    AppLogger.success(message);
    _show(context, successSnackBar(message, isDark: _isDark(context)));
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    AppLogger.warning(message);
    _show(context, warningSnackBar(message, isDark: _isDark(context)));
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    AppLogger.info(message);
    _show(context, infoSnackBar(message, isDark: _isDark(context)));
  }

  // ── SnackBar builders — public for call sites that captured a
  //    ScaffoldMessenger before an await/pop invalidated their context. ──

  static SnackBar errorSnackBar(String message, {required bool isDark}) =>
      _bar(
        message:       message,
        icon:          Icons.error_outline,
        color:         isDark ? AppTheme.darkError : AppTheme.lightError,
        duration:      const Duration(seconds: 4),
        showCloseIcon: true,
      );

  static SnackBar successSnackBar(String message, {required bool isDark}) =>
      _bar(
        message:  message,
        icon:     Icons.check_circle,
        color:    isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
        duration: const Duration(seconds: 3),
      );

  static SnackBar warningSnackBar(String message, {required bool isDark}) =>
      _bar(
        message:  message,
        icon:     Icons.warning_amber_rounded,
        color:    isDark ? AppTheme.darkWarning : AppTheme.lightWarning,
        duration: const Duration(seconds: 3),
      );

  static SnackBar infoSnackBar(String message, {required bool isDark}) =>
      _bar(
        message:  message,
        icon:     Icons.info_outline,
        color:    isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
        duration: const Duration(seconds: 3),
      );

  /// WCAG-safe foreground for a snackbar background. Fixed white text fails
  /// 4.5:1 on the light tokens (worst on dark-theme pastels like
  /// darkWarning #FBBF24 ≈ 1.6:1) — pick ink by background luminance instead.
  static Color onColor(Color background) =>
      background.computeLuminance() > 0.179
          ? const Color(0xFF111827)
          : Colors.white;

  static SnackBar _bar({
    required String   message,
    required IconData icon,
    required Color    color,
    required Duration duration,
    bool showCloseIcon = false,
  }) {
    final Color fg = onColor(color);
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:      fg,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:         const EdgeInsets.all(16),
      duration:       duration,
      showCloseIcon:  showCloseIcon,
      closeIconColor: fg,
    );
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static void _show(BuildContext context, SnackBar bar) {
    if (!context.mounted) return;
    // Replace, don't queue — a backlog of stale snackbars is worse than none.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(bar);
  }
}
