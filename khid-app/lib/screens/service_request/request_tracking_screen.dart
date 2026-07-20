// lib/screens/service_request/request_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/message_enums.dart';
import '../../models/service_request_enhanced_model.dart';
import '../../providers/core_providers.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/back_button.dart';
import 'widgets/tracking_body.dart';

class RequestTrackingScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestTrackingScreen({super.key, required this.requestId});

  @override
  ConsumerState<RequestTrackingScreen> createState() =>
      _RequestTrackingScreenState();
}

class _RequestTrackingScreenState
    extends ConsumerState<RequestTrackingScreen> {
  bool _hasAutoNavRating = false;

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final requestAsync =
        ref.watch(serviceRequestStreamProvider(widget.requestId));

    ref.listen<AsyncValue<ServiceRequestEnhancedModel?>>(
      serviceRequestStreamProvider(widget.requestId),
      (_, next) {
        final req = next.valueOrNull;
        if (req == null) return;
        if (req.status == ServiceStatus.completed &&
            !req.isRatedByClient &&
            !_hasAutoNavRating) {
          _hasAutoNavRating = true;
          if (mounted) {
            context.push(
              AppRoutes.clientRating.replaceAll(':id', widget.requestId),
            );
          }
        }
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // Deep-link target (job_started/completed push) — reached with go() on
      // cold start; guard sends system-back home instead of exiting.
      child: AppBackGuard(
        child: Scaffold(
          body: SafeArea(
            child: requestAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(context.tr('tracking.error_loading')),
              ),
              data: (request) {
                if (request == null) {
                  return Center(
                      child: Text(context.tr('tracking.not_found')));
                }
                return TrackingBody(request: request, isDark: isDark);
              },
            ),
          ),
        ),
      ),
    );
  }
}
