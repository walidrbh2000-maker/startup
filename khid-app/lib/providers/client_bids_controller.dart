// lib/providers/client_bids_controller.dart
//
// Client-side bid acceptance for one service request.
//
// IDEMPOTENCY: enforced by the backend on the natural key — accepting a bid
// that is already Accepted for the same owner/selectedBidId returns success
// as a no-op (bids.service.ts accept()). A retry after a network timeout is
// therefore safe without any client-generated key.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/worker_bid_model.dart';
import '../providers/core_providers.dart';
import '../services/worker_bid_service.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CLIENT BIDS STATE
// ═══════════════════════════════════════════════════════════════════════════

class ClientBidsState {
  final bool isAccepting;
  final String? acceptingBidId;
  final String? error;
  final bool success;

  const ClientBidsState({
    this.isAccepting = false,
    this.acceptingBidId,
    this.error,
    this.success = false,
  });

  /// Alias exposed to the UI layer (bids_list_screen listens on this).
  String? get errorMessage => error;

  ClientBidsState copyWith({
    bool? isAccepting,
    String? acceptingBidId,
    String? error,
    bool? success,
  }) {
    return ClientBidsState(
      isAccepting: isAccepting ?? this.isAccepting,
      acceptingBidId: acceptingBidId ?? this.acceptingBidId,
      error: error,
      success: success ?? this.success,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIENT BIDS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class ClientBidsNotifier extends StateNotifier<ClientBidsState> {
  final WorkerBidService _bidService;
  final String _requestId;

  ClientBidsNotifier(this._bidService, this._requestId)
      : super(const ClientBidsState());

  /// Errors surface through state (the screen listens on errorMessage) —
  /// never rethrown: the call sites are fire-and-forget button callbacks.
  Future<void> acceptBid({
    required String requestId,
    required WorkerBidModel bid,
  }) async {
    if (state.isAccepting || !mounted) return;

    state = state.copyWith(
      isAccepting: true,
      acceptingBidId: bid.id,
      error: null,
      success: false,
    );

    try {
      await _bidService.acceptBid(requestId: requestId, bid: bid);
      if (!mounted) return;
      state = state.copyWith(
        isAccepting: false,
        acceptingBidId: null,
        error: null,
        success: true,
      );
    } catch (e) {
      AppLogger.error('ClientBidsNotifier.acceptBid', e);
      if (!mounted) return;
      state = state.copyWith(
        isAccepting: false,
        acceptingBidId: null,
        error: errorKeyFor(e),
      );
    }
  }

  Future<void> withdrawBid({required String bidId}) async {
    try {
      await _bidService.withdrawBid(bidId: bidId, requestId: _requestId);
    } catch (e) {
      AppLogger.error('ClientBidsNotifier.withdrawBid', e);
      if (mounted) state = state.copyWith(error: errorKeyFor(e));
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetSuccess() {
    state = state.copyWith(success: false);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════
//
// autoDispose.family — same lifecycle as the sibling action controllers
// (mission / bidManagement / jobAction / cancelRequest): released when the
// bids screen leaves the stack, so no per-request state outlives its screen.

final clientBidsControllerProvider = StateNotifierProvider.autoDispose
    .family<ClientBidsNotifier, ClientBidsState, String>(
  (ref, requestId) {
    final bidService = ref.watch(workerBidServiceProvider);
    return ClientBidsNotifier(bidService, requestId);
  },
);
