// test/error_key_for_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmeti/services/api_service.dart';
import 'package:khidmeti/services/service_request_service.dart';
import 'package:khidmeti/services/worker_bid_service.dart';
import 'package:khidmeti/utils/app_theme.dart';
import 'package:khidmeti/utils/error_handler.dart';

void main() {
  test('errorKeyFor maps exception codes to errors.* translation keys', () {
    expect(errorKeyFor(const ApiServiceException('x', code: 'NETWORK_ERROR')),
        'errors.network');
    expect(errorKeyFor(const ApiServiceException('x', code: 'UNAUTHENTICATED')),
        'errors.unauthorized');
    expect(errorKeyFor(const ApiServiceException('x', code: 'NOT_FOUND')),
        'errors.not_found');
    expect(
        errorKeyFor(WorkerBidServiceException('x', code: 'DUPLICATE_BID')),
        'errors.duplicate_bid');
    expect(errorKeyFor(WorkerBidServiceException('x', code: 'RATE_LIMIT')),
        'errors.too_many_requests');
    expect(errorKeyFor(WorkerBidServiceException('x', code: 'INVALID_PRICE')),
        'errors.validation');
    expect(
        errorKeyFor(
            ServiceRequestServiceException('x', code: 'TITLE_TOO_SHORT')),
        'errors.validation');
    expect(
        errorKeyFor(
            ServiceRequestServiceException('x', code: 'CANCEL_TIMEOUT')),
        'errors.connection');
    expect(errorKeyFor(TimeoutException('x')), 'errors.connection');
    // Unknown codes and foreign exceptions never leak raw text.
    expect(errorKeyFor(WorkerBidServiceException('x', code: 'STREAM_ERROR')),
        'errors.generic');
    expect(errorKeyFor(Exception('raw dev text')), 'errors.generic');
    expect(errorKeyFor(null), 'errors.generic');
  });

  test('snackbar foreground clears WCAG 4.5:1 on every semantic token', () {
    const tokens = [
      AppTheme.lightError,
      AppTheme.lightSuccess,
      AppTheme.lightWarning,
      AppTheme.lightAccent,
      AppTheme.darkError,
      AppTheme.darkSuccess,
      AppTheme.darkWarning,
      AppTheme.darkAccent,
    ];
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final bg in tokens) {
      expect(
        contrast(bg, ErrorHandler.onColor(bg)),
        greaterThanOrEqualTo(4.5),
        reason: 'foreground on $bg',
      );
    }
  });
}
