// lib/screens/worker_jobs/widgets/my_bid_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/message_enums.dart';
import '../../../models/worker_bid_model.dart';
import '../../../providers/bid_management_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/localization.dart';

class MyBidCard extends ConsumerWidget {
  final WorkerBidModel bid;
  final bool isDark;
  final Color accent;

  const MyBidCard({
    super.key,
    required this.bid,
    required this.isDark,
    required this.accent,
  });

  Color _bidStatusColor() {
    switch (bid.status) {
      case BidStatus.pending:
        return isDark ? AppTheme.warningAmber : AppTheme.amberTextLight;
      case BidStatus.accepted:
        return AppTheme.acceptGreen;
      case BidStatus.declined:
      case BidStatus.expired:
        return isDark ? AppTheme.statusCancelledDark : AppTheme.lightError;
      case BidStatus.withdrawn:
        return isDark
            ? AppTheme.darkSecondaryText
            : AppTheme.lightSecondaryText;
    }
  }

  Future<void> _confirmWithdraw(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('worker_my_bids.withdraw_confirm_title')),
        content: Text(context.tr('worker_my_bids.withdraw_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AppTheme.darkError : AppTheme.lightError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('worker_my_bids.withdraw'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(bidManagementControllerProvider(bid.id).notifier)
          .withdrawBid(
            bidId: bid.id,
            requestId: bid.serviceRequestId,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state      = ref.watch(bidManagementControllerProvider(bid.id));
    final color      = _bidStatusColor();
    final canWithdraw = bid.status == BidStatus.pending;

    // Show controller error via SnackBar once.
    ref.listen<BidManagementState>(
      bidManagementControllerProvider(bid.id),
      (_, next) {
        if (next.errorMessage != null) {
          ErrorHandler.showErrorSnackBar(
            context,
            context.tr(next.errorMessage!),
          );
          ref
              .read(bidManagementControllerProvider(bid.id).notifier)
              .clearError();
        }
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withValues(alpha: 0.6)
            : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('worker_my_bids.offer_for'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText,
                            ),
                      ),
                      Text(
                        '${bid.proposedPrice.toStringAsFixed(0)} ${context.tr('common.currency')} · ${bid.estimatedDurationLabel}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                // Status pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Text(
                    bid.status.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            if (canWithdraw) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Semantics(
                button: true,
                label: context.tr('worker_my_bids.withdraw'),
                child: GestureDetector(
                  onTap: state.isWithdrawing
                      ? null
                      : () => _confirmWithdraw(context, ref),
                  child: state.isWithdrawing
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? AppTheme.statusCancelledDark
                                  : AppTheme.lightError,
                            ),
                          ),
                        )
                      : Text(
                          context.tr('worker_my_bids.withdraw'),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: isDark
                                    ? AppTheme.statusCancelledDark
                                    : AppTheme.lightError,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
