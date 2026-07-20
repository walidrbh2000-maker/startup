// lib/screens/service_request/widgets/request_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/message_enums.dart';
import '../../../models/service_request_enhanced_model.dart';
import '../../../providers/cancel_request_controller.dart';
import '../../../providers/core_providers.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/localization.dart';

// ============================================================================
// REQUEST CARD
// ============================================================================

class RequestCard extends ConsumerWidget {
  final ServiceRequestEnhancedModel request;
  final bool  isDark;
  final Color accentColor;

  const RequestCard({
    super.key,
    required this.request,
    required this.isDark,
    required this.accentColor,
  });

  Color _statusColor(bool isDark) =>
      AppTheme.getStatusColor(request.status, isDark);

  String _statusLabel(BuildContext context) {
    final s = request.status;
    if (s == ServiceStatus.open)              return context.tr('requests.open');
    if (s == ServiceStatus.awaitingSelection) {
      return '${request.bidCount} ${context.tr('bids.offers')}';
    }
    if (s == ServiceStatus.bidSelected) return context.tr('requests.selected');
    if (s == ServiceStatus.inProgress)  return context.tr('requests.in_progress');
    if (s == ServiceStatus.completed)   return context.tr('requests.completed');
    if (s == ServiceStatus.cancelled)   return context.tr('requests.cancelled');
    if (s == ServiceStatus.expired)     return context.tr('requests.expired');
    return s.displayName;
  }

  void _onTap(BuildContext context) {
    final s = request.status;
    if (s == ServiceStatus.open || s == ServiceStatus.awaitingSelection) {
      context.push(AppRoutes.bidsListScreen.replaceAll(':id', request.id));
    } else if (s == ServiceStatus.bidSelected ||
        s == ServiceStatus.inProgress ||
        s == ServiceStatus.completed) {
      context.push(AppRoutes.requestTracking.replaceAll(':id', request.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color        = _statusColor(isDark);
    final serviceColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final serviceIcon  = AppTheme.getProfessionIcon(request.serviceType);
    final dateStr =
        DateFormat('d MMM', Localizations.localeOf(context).languageCode)
            .format(request.scheduledDate);
    final timeStr =
        '${request.scheduledTime.hour.toString().padLeft(2, '0')}:'
        '${request.scheduledTime.minute.toString().padLeft(2, '0')}';

    final showBidsBadge =
        request.status == ServiceStatus.awaitingSelection &&
            request.bidCount > 0;
    final isActive = request.status == ServiceStatus.bidSelected ||
        request.status == ServiceStatus.inProgress;
    final canCancel = request.status.canCancel;

    return Semantics(
      button: true,
      label:  '${context.tr('services.${request.serviceType}')} · '
              '${_statusLabel(context)}',
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkSurface.withValues(alpha: 0.6)
                : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkCardBorderOverlay
                  : AppTheme.lightCardBorderOverlay,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width:  AppConstants.serviceIconContainerSize,
                      height: AppConstants.serviceIconContainerSize,
                      decoration: BoxDecoration(
                        color: serviceColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                      child: Icon(serviceIcon, size: 20, color: serviceColor),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('services.${request.serviceType}'),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateStr · $timeStr',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingSm,
                        vertical:   AppConstants.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color:        color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Text(
                        _statusLabel(context),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color:      color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),

                // ── Address ────────────────────────────────────────────
                if (request.userAddress.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Row(
                    children: [
                      Icon(
                        AppIcons.locationOutlined,
                        size:  12,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Expanded(
                        child: Text(
                          request.userAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Bids badge ─────────────────────────────────────────
                if (showBidsBadge) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSm),
                      border: Border.all(
                          color: AppTheme.warningAmber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.bid,
                            size: 13,
                            color: isDark
                                ? AppTheme.warningAmber
                                : AppTheme.amberTextLight),
                        const SizedBox(width: 5),
                        Text(
                          '${request.bidCount} ${context.tr('bids.view_offers')}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.warningAmber
                                        : AppTheme.amberTextLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(width: AppConstants.spacingXs),
                        Icon(AppIcons.forward,
                            size: 11,
                            color: isDark
                                ? AppTheme.warningAmber
                                : AppTheme.amberTextLight),
                      ],
                    ),
                  ),
                ],

                // ── Worker info (active) ────────────────────────────────
                if (isActive && request.workerName != null) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Container(
                    height: 1,
                    color:  (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Row(
                    children: [
                      Container(
                        width:  26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            request.workerName!.isNotEmpty
                                ? request.workerName![0].toUpperCase()
                                : '?',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:      color,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   AppConstants.fontSizeXxs,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Expanded(
                        child: Text(
                          request.workerName!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (request.agreedPrice != null)
                        Text(
                          '${request.agreedPrice!.toStringAsFixed(0)} '
                          '${context.tr('common.currency')}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:      color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                ],

                // ── Cancel button ──────────────────────────────────────
                if (canCancel) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  _CancelButton(requestId: request.id, isDark: isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CANCEL BUTTON
// ============================================================================

class _CancelButton extends ConsumerWidget {
  final String requestId;
  final bool   isDark;

  const _CancelButton({required this.requestId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cancelRequestControllerProvider(requestId));

    ref.listen<CancelRequestState>(
      cancelRequestControllerProvider(requestId),
      (_, next) {
        if (next.errorKey != null) {
          ErrorHandler.showErrorSnackBar(
            context,
            context.tr(next.errorKey!),
          );
          ref
              .read(cancelRequestControllerProvider(requestId).notifier)
              .clearError();
        }
      },
    );

    if (state.isLoading) {
      return const SizedBox(
        width:  16,
        height: 16,
        child:  CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Semantics(
      button: true,
      label:  context.tr('requests.cancel'),
      child: GestureDetector(
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title:   Text(context.tr('requests.cancel_confirm_title')),
              content: Text(context.tr('requests.cancel_confirm_body')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.tr('common.no')),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    context.tr('common.yes'),
                    style: TextStyle(
                        color: isDark
                            ? AppTheme.darkError
                            : AppTheme.lightError),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            ref
                .read(cancelRequestControllerProvider(requestId).notifier)
                .cancel();
          }
        },
        child: Text(
          context.tr('requests.cancel'),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppTheme.statusCancelledDark
                    : AppTheme.lightError,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
