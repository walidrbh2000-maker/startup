// lib/providers/worker_home_controller.dart
//
// OPTIMISTIC UPDATE PATTERN for toggleOnlineStatus()
//
// PROBLEM:
//   Toggle tap → API call (~500ms) → stream null event → re-fetch (~300ms)
//   → state update = 800ms-2s total latency.
//   The user sees no visual feedback until the server round-trip completes,
//   so they tap again thinking nothing happened — causing double-toggle bugs.
//
// SOLUTION — Optimistic Update with Rollback:
//   Pattern used by Twitter likes, Spotify follows, etc.:
//
//   1. BEFORE network call: capture previous state, apply new state immediately
//   2. DURING network call: UI already shows the new state (instant feedback)
//   3. ON SUCCESS: do nothing — the stream will eventually confirm
//   4. ON ERROR: rollback to previous state + show error toast
//
//   The stream update (step 3) arrives later and is idempotent — it just
//   overwrites with the same value the optimistic update already applied.
//
// IMPLEMENTATION:
//   - WorkerModel.copyWith(isOnline: newIsOnline) applies the optimistic state
//   - The snapshot before the call is saved as `previousWorker` for rollback
//   - isTogglingOnline blocks double-taps during the in-flight call
//   - On any exception, previousWorker is restored as AsyncValue.data(...)
//
// _fetchWorkerImmediately() runs before the stream subscription so data
// appears as soon as the API responds, independent of stream behavior.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message_enums.dart';
import '../models/service_request_enhanced_model.dart';
import '../models/worker_model.dart';
import '../providers/core_providers.dart';
import '../providers/location_controller.dart';
import '../providers/location_permission_controller.dart';
import '../utils/logger.dart';

// ============================================================================
// STATE
// ============================================================================

enum GoOnlineBlockReason {
  permissionDenied,
  permissionPermanentlyDenied,
  gpsHardwareDisabled,
}

class WorkerHomeState {
  final AsyncValue<WorkerModel> workerAsync;
  final bool isTogglingOnline;
  final List<ServiceRequestEnhancedModel> recentRequests;
  final bool isLoadingRequests;
  final String? requestsError;
  final bool isRefreshing;
  final String? toggleError;
  final GoOnlineBlockReason? goOnlineBlockReason;

  const WorkerHomeState({
    this.workerAsync = const AsyncValue.loading(),
    this.isTogglingOnline = false,
    this.recentRequests = const [],
    this.isLoadingRequests = false,
    this.requestsError,
    this.isRefreshing = false,
    this.toggleError,
    this.goOnlineBlockReason,
  });

  int get pendingCount =>
      recentRequests.where((r) => r.status == ServiceStatus.pending).length;

  int get activeCount => recentRequests
      .where((r) =>
          r.status == ServiceStatus.accepted ||
          r.status == ServiceStatus.inProgress)
      .length;

  int get completedCount =>
      recentRequests.where((r) => r.status == ServiceStatus.completed).length;

  WorkerModel? get worker      => workerAsync.value;
  bool get isOnline            => worker?.isOnline ?? false;
  bool get isWorkerLoaded      => workerAsync is AsyncData;
  bool get isWorkerLoading     => workerAsync is AsyncLoading;
  bool get isWorkerError       => workerAsync is AsyncError;

  WorkerHomeState copyWith({
    AsyncValue<WorkerModel>? workerAsync,
    bool? isTogglingOnline,
    List<ServiceRequestEnhancedModel>? recentRequests,
    bool? isLoadingRequests,
    String? requestsError,
    bool? isRefreshing,
    String? toggleError,
    GoOnlineBlockReason? goOnlineBlockReason,
    bool clearToggleError         = false,
    bool clearRequestsError       = false,
    bool clearGoOnlineBlockReason = false,
  }) {
    return WorkerHomeState(
      workerAsync:       workerAsync       ?? this.workerAsync,
      isTogglingOnline:  isTogglingOnline  ?? this.isTogglingOnline,
      recentRequests:    recentRequests    ?? this.recentRequests,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      requestsError: clearRequestsError
          ? null
          : (requestsError ?? this.requestsError),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      toggleError:  clearToggleError ? null : (toggleError ?? this.toggleError),
      goOnlineBlockReason: clearGoOnlineBlockReason
          ? null
          : (goOnlineBlockReason ?? this.goOnlineBlockReason),
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

class WorkerHomeController extends StateNotifier<WorkerHomeState> {
  final Ref _ref;

  StreamSubscription<WorkerModel?>?                      _workerSub;
  StreamSubscription<List<ServiceRequestEnhancedModel>>? _requestsSub;

  /// Tracked uid for re-fetch on stream null and manual refresh.
  String? _trackedUid;

  WorkerHomeController(this._ref) : super(const WorkerHomeState()) {
    _initialize();
  }

  // --------------------------------------------------------------------------
  // Public API — toggle (OPTIMISTIC UPDATE)
  // --------------------------------------------------------------------------

  Future<void> toggleOnlineStatus() async {
    // Guard: prevent double-tap during in-flight call.
    if (state.isTogglingOnline) return;

    final worker = state.worker;
    if (worker == null) return;

    final newIsOnline = !worker.isOnline;

    // ── STEP 1: Optimistic flip FIRST ─────────────────────────────────────────
    // The switch shows the new status instantly — no spinner, no wait. The GPS
    // pre-check and the server write happen afterwards; if anything blocks or
    // fails we roll back. Set onlineSince locally so the live usage counter
    // starts ticking immediately on going online; fold the ending session into
    // today's usageSeconds on going offline so the frozen counter matches what
    // the server will persist (daily bucket, reset at 00:00).
    final now = DateTime.now();
    final previousWorker  = worker;
    final optimisticWorker = newIsOnline
        ? worker.copyWith(isOnline: true, onlineSince: now)
        : worker.copyWith(
            isOnline:     false,
            onlineSince:  null,
            usageSeconds: worker.usageSecondsAt(now),
            usageDay:     WorkerModel.dayKey(now),
          );

    state = state.copyWith(
      workerAsync:              AsyncValue.data(optimisticWorker),
      isTogglingOnline:         true,
      clearToggleError:         true,
      clearGoOnlineBlockReason: true,
    );

    AppLogger.info(
        'WorkerHomeController: optimistic toggle → isOnline=$newIsOnline');

    try {
      // ── STEP 2: Pre-flight permission / GPS check (only when going online) ──
      // Runs after the optimistic flip; on block we roll the switch back and
      // surface the reason.
      if (newIsOnline) {
        final blockReason = await _resolveGoOnlineBlockReason();
        if (blockReason != null) {
          AppLogger.warning(
              'WorkerHomeController: Go Online blocked — $blockReason');
          if (mounted) {
            state = state.copyWith(
              workerAsync:         AsyncValue.data(previousWorker),
              goOnlineBlockReason: blockReason,
            );
          }
          return;
        }
      }

      // ── STEP 3: Side effects (GPS capture, cell assignment, native service)
      if (newIsOnline) {
        await _captureGpsBeforeGoingOnline(worker.id);
      } else {
        _stopNativeLocationService();
      }

      // ── STEP 4: Persist to backend ──────────────────────────────────────────
      await _ref
          .read(firestoreServiceProvider)
          .updateWorkerStatus(worker.id, newIsOnline)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
              'Worker status update timed out after 10s',
            ),
          );

      AppLogger.info(
          'WorkerHomeController: status confirmed by server → '
          'isOnline=$newIsOnline');

      // ── STEP 5: Success — no state change needed.
      // The stream will eventually deliver a confirmation event from the
      // server; when it does, it will overwrite with the same value and
      // the transition is invisible to the user.

    } catch (e) {
      AppLogger.error('WorkerHomeController.toggleOnlineStatus', e);

      if (!mounted) return;

      // ── ROLLBACK: restore the state the user started from.
      // The optimistic update is reverted — the switch snaps back.
      state = state.copyWith(
        workerAsync:  AsyncValue.data(previousWorker),
        toggleError:  e.toString(),
      );

      AppLogger.warning(
          'WorkerHomeController: rollback — restored isOnline='
          '${previousWorker.isOnline}');
    } finally {
      if (mounted) state = state.copyWith(isTogglingOnline: false);
    }
  }

  // --------------------------------------------------------------------------
  // Public API — job lifecycle
  // --------------------------------------------------------------------------

  Future<void> acceptRequest(String requestId) async {
    AppLogger.info('WorkerHomeController: accepting request $requestId');
    await _updateRequestStatus(requestId, ServiceStatus.accepted);
  }

  Future<void> declineRequest(String requestId) async {
    AppLogger.info('WorkerHomeController: declining request $requestId');
    await _updateRequestStatus(requestId, ServiceStatus.declined);
  }

  Future<void> markInProgress(String requestId) async {
    AppLogger.info('WorkerHomeController: marking in-progress $requestId');
    await _updateRequestStatus(requestId, ServiceStatus.inProgress);
  }

  Future<void> markCompleted(String requestId) async {
    AppLogger.info('WorkerHomeController: marking completed $requestId');
    await _updateRequestStatus(requestId, ServiceStatus.completed);
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);
    try {
      final uid = _trackedUid;
      if (uid != null) {
        final refreshed =
            await _ref.read(firestoreServiceProvider).getWorker(uid);
        if (!mounted) return;
        if (refreshed != null) {
          state = state.copyWith(workerAsync: AsyncValue.data(refreshed));
          await _loadRequests(uid);
        }
      }
    } catch (e) {
      AppLogger.error('WorkerHomeController.refresh', e);
    } finally {
      if (mounted) state = state.copyWith(isRefreshing: false);
    }
  }

  void clearToggleError() =>
      state = state.copyWith(clearToggleError: true);

  void clearGoOnlineBlock() =>
      state = state.copyWith(clearGoOnlineBlockReason: true);

  // --------------------------------------------------------------------------
  // Private — GPS / permission gate
  // --------------------------------------------------------------------------

  Future<GoOnlineBlockReason?> _resolveGoOnlineBlockReason() async {
    final permState = _ref.read(locationPermissionControllerProvider);

    try {
      final locationService = _ref.read(locationServiceProvider);
      final gpsOn = await locationService.isLocationServiceEnabled();
      if (!gpsOn) {
        _ref.read(locationPermissionControllerProvider.notifier).recheck();
        return GoOnlineBlockReason.gpsHardwareDisabled;
      }
    } catch (e) {
      AppLogger.warning(
          'WorkerHomeController: GPS check failed — blocking: $e');
      return GoOnlineBlockReason.gpsHardwareDisabled;
    }

    if (permState.needsSettings) return GoOnlineBlockReason.permissionPermanentlyDenied;
    if (!permState.isGranted)    return GoOnlineBlockReason.permissionDenied;
    return null;
  }

  // --------------------------------------------------------------------------
  // Private — GPS capture + cell assignment (going online)
  // --------------------------------------------------------------------------

  Future<void> _captureGpsBeforeGoingOnline(String workerId) async {
    // GPS location capture
    try {
      await _ref.read(userLocationControllerProvider.notifier).retryLocation();
      final locState = _ref.read(userLocationControllerProvider);
      if (locState.userLocation != null) {
        await _ref.read(firestoreServiceProvider).updateWorkerLocation(
          workerId,
          locState.userLocation!.latitude,
          locState.userLocation!.longitude,
        );
        AppLogger.info(
            'WorkerHomeController: GPS captured — '
            '${locState.userLocation!.latitude}, '
            '${locState.userLocation!.longitude}');
      }
    } catch (gpsError) {
      AppLogger.warning(
          'WorkerHomeController: GPS capture failed (non-fatal): $gpsError');
    }

    // Geographic cell assignment
    try {
      final locState = _ref.read(userLocationControllerProvider);
      if (locState.userLocation != null) {
        await _ref.read(geographicGridServiceProvider).assignWorkerToCell(
          workerId:  workerId,
          latitude:  locState.userLocation!.latitude,
          longitude: locState.userLocation!.longitude,
        );
        AppLogger.info('WorkerHomeController: cell assigned');
      }
    } catch (cellError) {
      AppLogger.warning(
          'WorkerHomeController: cell assignment failed (non-fatal): $cellError');
    }

    // Native background location service
    try {
      await _ref.read(nativeChannelServiceProvider).startLocationService(
        userId:   workerId,
        isWorker: true,
      );
      AppLogger.info('WorkerHomeController: background location started');
    } catch (e) {
      AppLogger.warning('WorkerHomeController: native start failed: $e');
    }
  }

  void _stopNativeLocationService() {
    _ref.read(nativeChannelServiceProvider).stopLocationService().catchError(
      (e) => AppLogger.warning(
          'WorkerHomeController: native stop failed: $e'),
    );
  }

  // --------------------------------------------------------------------------
  // Private — initialisation
  // --------------------------------------------------------------------------

  void _initialize() {
    final uid = _ref.read(authServiceProvider).user?.uid;
    if (uid == null) {
      AppLogger.warning('WorkerHomeController: no auth user');
      state = state.copyWith(
        workerAsync: AsyncValue.error(
            Exception('User not authenticated'), StackTrace.current),
      );
      return;
    }
    _trackedUid = uid;
    AppLogger.info('WorkerHomeController: init uid=$uid');
    _subscribeToWorker(uid);
  }

  // --------------------------------------------------------------------------
  // Private — stream + immediate fetch (Bug 1c fix)
  // --------------------------------------------------------------------------

  void _subscribeToWorker(String uid) {
    _workerSub?.cancel();

    // Immediate fetch: guarantees data appears without waiting for stream.
    _fetchWorkerImmediately(uid);

    _workerSub = _ref
        .read(firestoreServiceProvider)
        .streamWorker(uid)
        .listen(
      (worker) async {
        if (!mounted) return;

        if (worker == null) {
          // null = change signal from RealtimeService — re-fetch silently.
          // Do NOT clear existing data (would cause unnecessary skeleton flash).
          AppLogger.debug(
              'WorkerHomeController: stream null → re-fetching');
          try {
            final refreshed =
                await _ref.read(firestoreServiceProvider).getWorker(uid);
            if (!mounted) return;
            if (refreshed != null) {
              // Only update if no optimistic toggle is in flight.
              // If isTogglingOnline, the stream event is stale — skip it.
              if (!state.isTogglingOnline) {
                state = state.copyWith(workerAsync: AsyncValue.data(refreshed));
              }
              _subscribeToRequests(uid);
            } else {
              state = state.copyWith(
                workerAsync: AsyncValue.error(
                    Exception('Worker profile not found'), StackTrace.current),
              );
            }
          } catch (e, st) {
            AppLogger.warning(
                'WorkerHomeController: re-fetch after null failed: $e');
            if (!mounted) return;
            if (state.workerAsync is AsyncLoading) {
              state = state.copyWith(workerAsync: AsyncValue.error(e, st));
            }
          }
          return;
        }

        AppLogger.debug(
            'WorkerHomeController: stream update — online=${worker.isOnline}');

        // Skip stream updates during an in-flight optimistic toggle.
        // The stream event may reflect the OLD server state before our write
        // committed — applying it would undo the optimistic update.
        if (!state.isTogglingOnline) {
          state = state.copyWith(workerAsync: AsyncValue.data(worker));
        }
        _subscribeToRequests(uid);
      },
      onError: (Object error) {
        AppLogger.error('WorkerHomeController stream error', error);
        if (!mounted) return;
        if (state.workerAsync is AsyncLoading) {
          state = state.copyWith(
              workerAsync: AsyncValue.error(error, StackTrace.current));
        }
      },
    );
  }

  Future<void> _fetchWorkerImmediately(String uid) async {
    try {
      final worker = await _ref.read(firestoreServiceProvider).getWorker(uid);
      if (!mounted) return;
      if (worker != null) {
        AppLogger.info(
            'WorkerHomeController: immediate fetch — online=${worker.isOnline}');
        state = state.copyWith(workerAsync: AsyncValue.data(worker));
        _subscribeToRequests(uid);

        // App relaunched while still online server-side: the native location
        // service only starts on TOGGLE, so re-ensure it here or the worker
        // looks online but silently stops sending positions.
        if (worker.isOnline) {
          _ref
              .read(nativeChannelServiceProvider)
              .startLocationService(userId: uid, isWorker: true)
              .then((_) => AppLogger.info(
                  'WorkerHomeController: native location re-ensured'))
              .catchError((Object e) => AppLogger.warning(
                  'WorkerHomeController: native re-ensure failed: $e'));
        }
      }
    } catch (e) {
      AppLogger.warning(
          'WorkerHomeController: immediate fetch failed (stream fallback): $e');
    }
  }

  void _subscribeToRequests(String workerId) {
    if (_requestsSub != null) return;

    AppLogger.info('WorkerHomeController: subscribing to requests');
    state = state.copyWith(isLoadingRequests: true, clearRequestsError: true);

    _requestsSub = _ref
        .read(firestoreServiceProvider)
        .streamWorkerAssignedRequests(workerId, limit: 30)
        .listen(
      (requests) {
        if (!mounted) return;
        state = state.copyWith(
          recentRequests:    requests,
          isLoadingRequests: false,
        );
      },
      onError: (Object error) {
        AppLogger.error('WorkerHomeController requests stream error', error);
        if (!mounted) return;
        state = state.copyWith(
          isLoadingRequests: false,
          requestsError:     error.toString(),
        );
      },
    );
  }

  Future<void> _loadRequests(String workerId) async {
    _requestsSub?.cancel();
    _requestsSub = null;
    _subscribeToRequests(workerId);
  }

  Future<void> _updateRequestStatus(
    String requestId,
    ServiceStatus newStatus,
  ) async {
    try {
      final svc = _ref.read(firestoreServiceProvider);
      switch (newStatus) {
        case ServiceStatus.accepted:
        case ServiceStatus.inProgress:
          await svc.startJob(requestId);
          break;
        case ServiceStatus.completed:
          await svc.completeJob(requestId: requestId);
          break;
        case ServiceStatus.declined:
        case ServiceStatus.cancelled:
          await svc.cancelRequest(requestId);
          break;
        default:
          AppLogger.warning(
              'WorkerHomeController: unhandled status $newStatus — skipping');
          return;
      }
      AppLogger.info('WorkerHomeController: $requestId → $newStatus');
    } catch (e) {
      AppLogger.error('WorkerHomeController._updateRequestStatus', e);
      rethrow;
    }
  }

  @override
  void dispose() {
    AppLogger.debug('WorkerHomeController: disposing');
    _workerSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final workerHomeControllerProvider =
    StateNotifierProvider.autoDispose<WorkerHomeController, WorkerHomeState>(
  (ref) {
    final link = ref.keepAlive();
    ref.listen<bool>(isLoggedInProvider, (_, isLoggedIn) {
      if (!isLoggedIn) link.close();
    });
    return WorkerHomeController(ref);
  },
);
