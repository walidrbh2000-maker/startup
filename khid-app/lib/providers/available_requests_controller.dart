// lib/providers/available_requests_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_enhanced_model.dart';
import '../models/worker_bid_model.dart';
import '../models/message_enums.dart';
import '../models/worker_model.dart';
import '../utils/model_extensions.dart';
import 'core_providers.dart';

// ============================================================================
// FILTER ENUM
// ============================================================================

enum AvailableRequestsFilter {
  all,
  urgent,
  highBudget,
  noBids,
}

extension AvailableRequestsFilterLabel on AvailableRequestsFilter {
  String label(String Function(String) tr) {
    switch (this) {
      case AvailableRequestsFilter.all:
        return tr('worker_browse.filter_all');
      case AvailableRequestsFilter.urgent:
        return tr('worker_browse.filter_urgent');
      case AvailableRequestsFilter.highBudget:
        return tr('worker_browse.filter_high_budget');
      case AvailableRequestsFilter.noBids:
        return tr('worker_browse.filter_no_bids');
    }
  }
}

// ============================================================================
// STATE
// ============================================================================

class AvailableRequestsState {
  // FIX (P2, P5): replaced isLoading + errorMessage + allRequests triple with
  // AsyncValue<List<ServiceRequestEnhancedModel>> — matches workerJobsController
  // gold-standard pattern. Backward-compat getters preserve all call sites.
  final AsyncValue<List<ServiceRequestEnhancedModel>> requestsAsync;

  final AvailableRequestsFilter activeFilter;

  // Maintained by AvailableRequestsController._bidsSub — the set of request
  // IDs where the current worker has a PENDING bid.
  final Set<String> pendingBidRequestIds;

  const AvailableRequestsState({
    this.requestsAsync = const AsyncValue.loading(),
    this.activeFilter = AvailableRequestsFilter.all,
    this.pendingBidRequestIds = const {},
  });

  // ── Backward-compat getters — all call sites unchanged ───────────────────

  /// All loaded requests, or empty list while loading/erroring.
  List<ServiceRequestEnhancedModel> get allRequests =>
      requestsAsync.asData?.value ?? const [];

  /// True while the requests stream is initialising or re-loading.
  bool get isLoading => requestsAsync.isLoading;

  /// Error string if the stream failed, null otherwise.
  String? get errorMessage => requestsAsync.asError?.error.toString();

  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if the current worker already has a pending bid on [requestId].
  bool hasMyBid(String requestId) =>
      pendingBidRequestIds.contains(requestId);

  /// Filtered and sorted list, computed on read. The lists here are tens of
  /// items — a memo cache was tried and shipped a wipe-the-list bug; plain
  /// recomputation is cheap and cannot go stale.
  List<ServiceRequestEnhancedModel> get filteredRequests => _computeFiltered();

  List<ServiceRequestEnhancedModel> _computeFiltered() {
    switch (activeFilter) {
      case AvailableRequestsFilter.all:
        return allRequests;
      case AvailableRequestsFilter.urgent:
        return allRequests
            .where((r) => r.priority == ServicePriority.urgent)
            .toList();
      case AvailableRequestsFilter.highBudget:
        return allRequests
            .where((r) => r.budgetMax != null && r.budgetMax! >= 5000)
            .toList()
          ..sort((a, b) =>
              (b.budgetMax ?? 0).compareTo(a.budgetMax ?? 0));
      case AvailableRequestsFilter.noBids:
        return allRequests.where((r) => r.bidCount == 0).toList();
    }
  }

  AvailableRequestsState copyWith({
    AsyncValue<List<ServiceRequestEnhancedModel>>? requestsAsync,
    AvailableRequestsFilter? activeFilter,
    Set<String>? pendingBidRequestIds,
  }) {
    return AvailableRequestsState(
      requestsAsync:        requestsAsync        ?? this.requestsAsync,
      activeFilter:         activeFilter         ?? this.activeFilter,
      pendingBidRequestIds: pendingBidRequestIds ?? this.pendingBidRequestIds,
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class AvailableRequestsController
    extends StateNotifier<AvailableRequestsState> {
  final Ref _ref;
  StreamSubscription<List<ServiceRequestEnhancedModel>>? _requestsSub;
  StreamSubscription<List<WorkerBidModel>>?              _bidsSub;

  WorkerModel? _worker;
  String?      _workerId;

  AvailableRequestsController(this._ref)
      : super(const AvailableRequestsState()) {
    _init();
  }

  Future<void> _init() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    _workerId = userId;

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      _worker = await firestoreService.getWorker(userId);

      if (_worker == null) {
        if (!mounted) return;
        state = state.copyWith(
          requestsAsync: AsyncValue.error(
            'worker_not_found',
            StackTrace.current,
          ),
        );
        return;
      }

      // FIX (P0 — MIGRATION): profession est maintenant String? dans UserModel.
      // Un worker sans profession renseignée ne peut pas souscrire aux demandes
      // disponibles (serviceType est required String côté API).
      // On bloque ici avec un message clair plutôt que de crasher.
      final profession = _worker!.profession;
      if (profession == null || profession.isEmpty) {
        if (!mounted) return;
        state = state.copyWith(
          requestsAsync: AsyncValue.error(
            'worker_profession_missing',
            StackTrace.current,
          ),
        );
        if (kDebugMode) {
          debugPrint(
            '[AvailableRequestsController] Worker $userId has no profession set — '
            'cannot subscribe to available requests.',
          );
        }
        return;
      }

      _subscribeToRequests();
      _subscribeToBids(userId);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AvailableRequestsController] ERROR in _init: $e');
      }
      if (!mounted) return;
      state = state.copyWith(
        requestsAsync: AsyncValue.error(e, st),
      );
    }
  }

  void _subscribeToRequests() {
    if (_worker == null) return;

    // FIX (P0 — MIGRATION): profession est String? — guard obligatoire.
    // _init() vérifie déjà que profession != null avant d'appeler cette méthode,
    // mais on garde le guard ici en défense pour tout appel futur direct.
    final profession = _worker!.profession;
    if (profession == null || profession.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[AvailableRequestsController] _subscribeToRequests skipped: '
          'worker has no profession.',
        );
      }
      return;
    }

    state = state.copyWith(
      requestsAsync: const AsyncValue.loading(),
    );

    // Expand to neighbouring wilayas so a job just across a wilaya border is
    // still visible — mirrors the client-side worker search which already
    // crosses borders. Set dedupes own + neighbours.
    final ownWilaya = _worker!.wilayaCode ?? 31;
    final wilayaCodes = <int>{
      ownWilaya,
      ..._ref
          .read(wilayaManagerProvider)
          .getNeighboringWilayas(ownWilaya)
          .map((w) => w.code),
    }.toList();

    _requestsSub?.cancel();
    _requestsSub = _ref
        .read(firestoreServiceProvider)
        .streamAvailableRequests(
          wilayaCodes: wilayaCodes,
          serviceType: profession,             // ✅ String (non-null garanti)
        )
        .listen(
      (requests) {
        if (!mounted) return;
        state = state.copyWith(
          requestsAsync: AsyncValue.data(_sortByProximity(requests)),
          // cache invalidation is implicit: requestsAsync != null
        );
      },
      onError: (e, StackTrace st) {
        if (!mounted) return;
        state = state.copyWith(
          requestsAsync: AsyncValue.error(e, st),
        );
      },
    );
  }

  /// Sort available leads nearest-first, mirroring the client-side proximity
  /// ranking so the worker sees the closest jobs on top (the backend serves
  /// them in createdAt order only). Requests whose GPS is not yet resolved
  /// (0,0 sentinel) and unlocated workers keep their original order at the end.
  List<ServiceRequestEnhancedModel> _sortByProximity(
      List<ServiceRequestEnhancedModel> requests) {
    final w = _worker;
    if (w == null || w.latitude == null || w.longitude == null) return requests;
    double dist(ServiceRequestEnhancedModel r) =>
        (r.userLatitude == 0 && r.userLongitude == 0)
            ? double.infinity
            : w.distanceTo(r.userLatitude, r.userLongitude);
    return [...requests]..sort((a, b) => dist(a).compareTo(dist(b)));
  }

  void _subscribeToBids(String workerId) {
    _bidsSub?.cancel();
    _bidsSub = _ref
        .read(firestoreServiceProvider)
        .streamWorkerBids(workerId)
        .listen(
      (bids) {
        if (!mounted) return;
        final pendingIds = bids
            .where((b) => b.status == BidStatus.pending)
            .map((b) => b.serviceRequestId)
            .toSet();
        // Only pendingBidRequestIds changes — filteredRequests cache is NOT
        // invalidated, avoiding an unnecessary re-sort of the full list.
        state = state.copyWith(pendingBidRequestIds: pendingIds);
      },
      onError: (e) {
        // Non-fatal: bids stream failure does not block the requests list.
        if (kDebugMode) {
          debugPrint(
              '[AvailableRequestsController] WARNING: bids stream error: $e');
        }
      },
    );
  }

  void setFilter(AvailableRequestsFilter filter) {
    if (!mounted) return;
    state = state.copyWith(activeFilter: filter);
    // cache invalidation is implicit: activeFilter != null
  }

  void refresh() {
    if (_worker == null || _workerId == null) {
      _init();
      return;
    }
    _subscribeToRequests();
    _subscribeToBids(_workerId!);
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    _bidsSub?.cancel();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final availableRequestsControllerProvider = StateNotifierProvider.autoDispose<
    AvailableRequestsController, AvailableRequestsState>(
  (ref) => AvailableRequestsController(ref),
);
