// lib/services/api_service.dart
//
// MIGRATION — COLLECTION UNIFIÉE
// PATCH — Hybrid HTTP+WS streams (Bug 1 fix)
// PATCH — Bug 1 POST /bids 400 fix: createBid() now sends ONLY the fields
//   declared in CreateBidDto. ValidationPipe (forbidNonWhitelisted:true) in
//   main.ts rejects any unknown field with 400 before reaching the service.
//   bid.toMap() included id/status/createdAt/expiresAt/acceptedAt which are
//   all absent from CreateBidDto → instant 400.
// PATCH — Bug 2 fix: createOrUpdateUser/Worker no longer sends email='' in
//   payload. @IsEmail() @IsOptional() does NOT ignore empty string '' —
//   @IsOptional() only ignores null/undefined → 400 validation error.
// PATCH — Bug 3 fix: streamOnlineWorkersByWilayas and streamOnlineWorkersUnscoped
//   were pure WebSocket streams. Seeded workers (and any worker not currently
//   connected) never appear because they never emit WebSocket events.
//   These methods now use the same hybrid HTTP+WS pattern as service requests:
//   1. Immediate REST fetch populates the map on screen mount.
//   2. WebSocket snapshot (workers:snapshot) and live diff events (worker:location,
//      worker:status) keep markers updated in real time.
//   The RealtimeService handles workers:snapshot → re-triggers the REST fetch so
//   the list stays consistent with any delta that arrives between fetches.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/geographic_cell.dart';
import '../models/notification_model.dart';
import '../models/profession_model.dart';
import '../models/service_request_enhanced_model.dart';
import '../models/user_check_result.dart';
import '../models/user_model.dart';
import '../models/worker_bid_model.dart';
import '../models/worker_model.dart';
import 'api_cache.dart';
import 'device_id_service.dart';
import 'realtime_service.dart';

export 'api_cache.dart' show ApiServiceException;

class ApiServiceException implements Exception {
  final String  message;
  final String? code;
  final dynamic originalError;

  const ApiServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'ApiServiceException: $message${code != null ? ' ($code)' : ''}';
}

class ApiService {
  final String          _baseUrl;
  final RealtimeService _realtime;
  final http.Client     _http;

  final ApiCache<UserModel>                   _userCache;
  final ApiCache<WorkerModel>                 _workerCache;
  final ApiCache<ServiceRequestEnhancedModel> _requestCache;

  static const Duration _operationTimeout = Duration(seconds: 10);
  static const Duration _cacheTTL         = Duration(minutes: 15);
  static const int      _cacheMaxSize     = 100;

  bool  _isDisposed = false;
  Timer? _cacheCleanupTimer;

  /// Invoked whenever ANY response comes back 403 PIN_REQUIRED (wired by the
  /// router provider). Root-cause fix for mid-session gating: a PIN change on
  /// another device untrusts this one instantly — without this hook the app
  /// would show generic network errors until a cold restart instead of the
  /// PIN screen. Fires on every gated response; the listener de-dupes.
  void Function()? onPinRequired;

  /// Invoked whenever ANY response comes back 403 APPROVAL_PENDING (wired by the
  /// router provider). The account submitted worker/business verification
  /// documents and an admin has not yet approved — the router parks the user on
  /// the pending-approval screen. Fires on every gated response; the listener
  /// de-dupes.
  void Function()? onApprovalPending;

  static const String usersCollection           = 'users';
  static const String workersCollection         = 'workers';
  static const String serviceRequestsCollection = 'service_requests';
  static const String workerBidsCollection      = 'worker_bids';
  static const String notificationsCollection   = 'notifications';
  static const String cellsCollection           = 'geographic_cells';

  ApiService({
    required String         baseUrl,
    required RealtimeService realtime,
    http.Client?            httpClient,
  })  : _baseUrl  = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _realtime = realtime,
        _http     = httpClient ?? http.Client(),
        _userCache    = ApiCache(ttl: _cacheTTL, maxSize: _cacheMaxSize, tag: '[UserCache]'),
        _workerCache  = ApiCache(ttl: _cacheTTL, maxSize: _cacheMaxSize, tag: '[WorkerCache]'),
        _requestCache = ApiCache(ttl: _cacheTTL, maxSize: _cacheMaxSize, tag: '[RequestCache]') {
    startCacheCleanup();
  }

  // ── Auth token ─────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final user     = FirebaseAuth.instance.currentUser;
    final token    = await user?.getIdToken();
    final deviceId = DeviceIdService.current;
    return {
      'Content-Type':  'application/json',
      if (token != null)    'Authorization': 'Bearer $token',
      // Account-PIN device gate: identifies this install to the backend.
      if (deviceId != null) 'X-Device-Id':   deviceId,
    };
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  Future<dynamic> _get(String path) async {
    _ensureNotDisposed();
    final headers = await _authHeaders();
    final uri     = Uri.parse('$_baseUrl$path');
    try {
      final response = await _http.get(uri, headers: headers)
          .timeout(_operationTimeout);
      return _handleResponse(response);
    } on ApiServiceException {
      rethrow;
    } catch (e) {
      throw ApiServiceException('GET $path failed', code: 'NETWORK_ERROR', originalError: e);
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    _ensureNotDisposed();
    final headers = await _authHeaders();
    final uri     = Uri.parse('$_baseUrl$path');
    try {
      final response = await _http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_operationTimeout);
      return _handleResponse(response);
    } on ApiServiceException {
      rethrow;
    } catch (e) {
      throw ApiServiceException('POST $path failed', code: 'NETWORK_ERROR', originalError: e);
    }
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    _ensureNotDisposed();
    final headers = await _authHeaders();
    final uri     = Uri.parse('$_baseUrl$path');
    try {
      final response = await _http
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(_operationTimeout);
      return _handleResponse(response);
    } on ApiServiceException {
      rethrow;
    } catch (e) {
      throw ApiServiceException('PATCH $path failed', code: 'NETWORK_ERROR', originalError: e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['success'] == true && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }
    String message = 'Request failed (${response.statusCode})';
    String? code;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? message;
      code    = response.statusCode.toString();
    } catch (_) {}
    if (response.statusCode == 401) throw ApiServiceException(message, code: 'UNAUTHENTICATED');
    // Account-PIN device gate: this device must pass /auth/verify-pin first.
    if (response.statusCode == 403 && message == 'PIN_REQUIRED') {
      onPinRequired?.call();
      throw const ApiServiceException('PIN_REQUIRED', code: 'PIN_REQUIRED');
    }
    // Document-approval gate: account awaiting admin approval of its documents.
    if (response.statusCode == 403 && message == 'APPROVAL_PENDING') {
      onApprovalPending?.call();
      throw const ApiServiceException('APPROVAL_PENDING', code: 'APPROVAL_PENDING');
    }
    // Bid-quota gate: machine-readable reasons from BidsService.submit —
    // each maps to a distinct message + CTA in the app (errorKeyFor).
    // DOCS_REQUIRED_FOR_B2B comes from subscription activation (expert/custom
    // B2B without admin-verified documents).
    if (response.statusCode == 403 &&
        const [
          'SUBSCRIPTION_REQUIRED',
          'BID_NOT_INCLUDED',
          'BID_QUOTA_EXHAUSTED',
          'DOCS_REQUIRED_FOR_B2B',
        ].contains(message)) {
      throw ApiServiceException(message, code: message);
    }
    if (response.statusCode == 403) throw ApiServiceException(message, code: 'PERMISSION_DENIED');
    if (response.statusCode == 404) throw ApiServiceException(message, code: 'NOT_FOUND');
    if (response.statusCode == 409) throw ApiServiceException(message, code: 'ALREADY_EXISTS');
    if (response.statusCode == 429) throw ApiServiceException(message, code: 'RESOURCE_EXHAUSTED');
    throw ApiServiceException(message, code: code ?? 'UNKNOWN');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HYBRID STREAM UTILITIES
  //
  // Pattern commun aux requests, bids, et workers :
  //   1. fetch() dès le premier listener → état initial immédiat depuis REST.
  //   2. wsSignal.listen(...) → re-fetch à chaque événement WS.
  //
  // Avantages vs WS-only :
  //   • Workers seedés (pas de connexion WS) apparaissent immédiatement.
  //   • Résistant aux déconnexions WS transitoires.
  //   • Cohérence garantie : l'état affiché vient toujours de MongoDB,
  //     jamais d'un état WS partiel.
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<ServiceRequestEnhancedModel>> _hybridRequestStream({
    required String httpQuery,
    required Stream<List<ServiceRequestEnhancedModel>> wsSignal,
  }) {
    late StreamController<List<ServiceRequestEnhancedModel>> ctrl;
    StreamSubscription<List<ServiceRequestEnhancedModel>>? wsSub;
    var hasData = false;

    Future<void> fetch() async {
      if (ctrl.isClosed) return;
      try {
        final data = await _get(httpQuery);
        if (data == null || ctrl.isClosed) return;
        final list = (data as List)
            .map((e) => ServiceRequestEnhancedModel.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList();
        hasData = true;
        ctrl.add(list);
      } catch (e) {
        // Transient re-fetch failure after the first success: keep the last
        // good list on screen instead of blanking it. Only surface errors on
        // the initial load, where there is nothing else to show.
        if (!ctrl.isClosed && !hasData) ctrl.addError(e);
      }
    }

    ctrl = StreamController<List<ServiceRequestEnhancedModel>>.broadcast(
      onListen: () {
        fetch();
        wsSub = wsSignal.listen(
          (_) => fetch(),
          onError: (Object e) { if (!ctrl.isClosed) ctrl.addError(e); },
          cancelOnError: false,
        );
      },
      onCancel: () {
        wsSub?.cancel();
        wsSub = null;
      },
    );

    return ctrl.stream;
  }

  Stream<List<WorkerBidModel>> _hybridBidStream({
    required String httpQuery,
    required Stream<List<WorkerBidModel>> wsSignal,
  }) {
    late StreamController<List<WorkerBidModel>> ctrl;
    StreamSubscription<List<WorkerBidModel>>? wsSub;
    var hasData = false;

    Future<void> fetch() async {
      if (ctrl.isClosed) return;
      try {
        final data = await _get(httpQuery);
        if (data == null || ctrl.isClosed) return;
        hasData = true;
        ctrl.add((data as List)
            .map((e) => WorkerBidModel.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList());
      } catch (e) {
        // Keep last good list on transient re-fetch failure (see request stream).
        if (!ctrl.isClosed && !hasData) ctrl.addError(e);
      }
    }

    ctrl = StreamController<List<WorkerBidModel>>.broadcast(
      onListen: () {
        fetch();
        wsSub = wsSignal.listen(
          (_) => fetch(),
          onError: (Object e) { if (!ctrl.isClosed) ctrl.addError(e); },
          cancelOnError: false,
        );
      },
      onCancel: () {
        wsSub?.cancel();
        wsSub = null;
      },
    );

    return ctrl.stream;
  }

  // ── Bug 3 fix ──────────────────────────────────────────────────────────────
  //
  // _hybridWorkerStream — identique aux deux méthodes ci-dessus mais typé
  // pour List<WorkerModel>.
  //
  // POURQUOI :
  //   streamOnlineWorkersByWilayas et streamOnlineWorkersUnscoped
  //   déléguaient directement à _realtime (WS pur). Les workers seedés
  //   n'ayant aucune connexion WebSocket, la carte restait vide même si
  //   MongoDB contenait 10 workers en ligne.
  //
  // COMPORTEMENT :
  //   • fetch() est appelé immédiatement au premier listener → affichage
  //     instantané des markers sur la carte.
  //   • wsSignal re-déclenche fetch() à chaque événement WS → live updates.
  //   • En cas d'erreur réseau, ctrl.addError() propage l'erreur au widget
  //     qui peut afficher un état d'erreur propre.
  //
  // NOTE SUR LES WORKERS HORS LIGNE :
  //   La requête REST utilise isOnline=true. Les workers offline ne sont
  //   pas envoyés dans le snapshot mais restent en base. Si le besoin
  //   apparaît de les afficher (ex: mode admin), retirer &isOnline=true.
  Stream<List<WorkerModel>> _hybridWorkerStream({
    required String httpQuery,
    required Stream<List<WorkerModel>> wsSignal,
  }) {
    late StreamController<List<WorkerModel>> ctrl;
    StreamSubscription<List<WorkerModel>>? wsSub;
    var hasData = false;

    Future<void> fetch() async {
      if (ctrl.isClosed) return;
      try {
        final data = await _get(httpQuery);
        if (data == null || ctrl.isClosed) return;
        hasData = true;
        ctrl.add(
          (data as List)
              .map((e) => WorkerModel.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      } catch (e) {
        // Keep last good marker set on transient re-fetch failure — a network
        // blip must not wipe the map (was cascading into a permanent fallback).
        if (!ctrl.isClosed && !hasData) ctrl.addError(e);
      }
    }

    ctrl = StreamController<List<WorkerModel>>.broadcast(
      onListen: () {
        fetch();
        wsSub = wsSignal.listen(
          (_) => fetch(),
          onError: (Object e) { if (!ctrl.isClosed) ctrl.addError(e); },
          cancelOnError: false,
        );
      },
      onCancel: () {
        wsSub?.cancel();
        wsSub = null;
      },
    );

    return ctrl.stream;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES USER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<UserModel?> getUser(String userId) async {
    _ensureNotDisposed();
    if (userId.trim().isEmpty) return null;
    final cached = _userCache.get(userId);
    if (cached != null) return cached;
    try {
      final data = await _get('/users/$userId');
      if (data == null) return null;
      final user = UserModel.fromJson(data as Map<String, dynamic>);
      _userCache.set(userId, user);
      return user;
    } on ApiServiceException catch (e) {
      if (e.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  /// Active l'abonnement de visibilité du worker (paiement stub côté backend).
  /// [tier] : 'basic' | 'pro' | 'business' | 'expert' | 'custom'.
  /// Pack custom : [hoursPerDay] (5–15), [bidsPerMonth] (0–30), plus options
  /// [priority] (+200 DA) et [b2b] (+850 DA, documents vérifiés requis) — le
  /// serveur recalcule le prix, jamais le client.
  /// Renvoie le document utilisateur mis à jour et rafraîchit le cache.
  Future<UserModel> activateSubscription(
    String userId, {
    required String tier,
    int? hoursPerDay,
    int? bidsPerMonth,
    bool priority = false,
    bool b2b = false,
  }) async {
    _ensureNotDisposed();
    final data = await _post('/users/$userId/subscription/activate', {
      'tier': tier,
      if (tier == 'custom') 'hoursPerDay': hoursPerDay,
      if (tier == 'custom') 'bidsPerMonth': bidsPerMonth,
      if (tier == 'custom') 'priority': priority,
      if (tier == 'custom') 'b2b': b2b,
    });
    final user = UserModel.fromJson(data as Map<String, dynamic>);
    _userCache.set(userId, user); // reflect the new subscription immediately
    return user;
  }

  Future<void> setUser(UserModel user) => createOrUpdateUser(user);

  Future<void> createOrUpdateUser(
    UserModel user, {
    String? language,
    List<String>? verificationDocs,
  }) async {
    _ensureNotDisposed();

    final payload = <String, dynamic>{
      'id':   user.id,
      'name': user.name,
      // Envoyer le rôle : distingue 'client' de 'business' (compte B2B). Sans
      // ça le backend applique le défaut 'client'.
      'role': user.role,
      // Ne pas envoyer email vide — @IsEmail() @IsOptional() rejette ''
      // avec un 400 car @IsOptional() n'ignore que null/undefined.
      if (user.email.isNotEmpty) 'email': user.email,
    };
    if (user.phoneNumber.isNotEmpty)  payload['phoneNumber']     = user.phoneNumber;
    if (user.latitude != null)        payload['latitude']        = user.latitude;
    if (user.longitude != null)       payload['longitude']       = user.longitude;
    if (user.profileImageUrl != null) payload['profileImageUrl'] = user.profileImageUrl;
    if (user.fcmToken != null)        payload['fcmToken']        = user.fcmToken;
    // Language drives server-rendered notification text (push + inbox).
    if (language != null && language.isNotEmpty) payload['language'] = language;
    // Optional (worker) / mandatory (business) verification documents →
    // backend flips the account to 'pending' admin review.
    if (verificationDocs != null && verificationDocs.isNotEmpty) {
      payload['verificationDocs'] = verificationDocs;
    }

    final data = await _post('/users', payload);
    if (data != null) {
      final updated = UserModel.fromJson(data as Map<String, dynamic>);
      _userCache.set(user.id, updated);
    }
  }

  Future<void> updateUserLocation(
    String userId, double lat, double lng, {
    String? cellId, int? wilayaCode, String? geoHash,
  }) async {
    _ensureNotDisposed();
    await _patch('/users/$userId/location', {
      'latitude':  lat,
      'longitude': lng,
      if (cellId     != null) 'cellId':     cellId,
      if (wilayaCode != null) 'wilayaCode': wilayaCode,
      if (geoHash    != null) 'geoHash':    geoHash,
    });
  }

  Future<void> updateFcmToken(String userId, String token) async {
    _ensureNotDisposed();
    await _patch('/users/$userId/fcm-token', {'fcmToken': token});
  }

  Future<void> updateUserFcmToken(String userId, String token) =>
      updateFcmToken(userId, token);

  // ── Auth check ─────────────────────────────────────────────────────────────

  /// Checks whether a Firebase UID has a backend profile.
  ///
  /// Calls GET /auth/check?uid=[uid] — requires a valid Firebase JWT.
  ///
  /// With [safeDefault] (the default) any error returns
  /// [UserCheckResult.newUser] so the caller navigates to /role-selection
  /// (no data loss risk). Pass safeDefault:false where a wrong "new user"
  /// answer is harmful (e.g. right after PIN verification, where it would
  /// send an existing user to role-selection) — errors then rethrow.
  Future<UserCheckResult> checkAuthUser(String uid, {bool safeDefault = true}) async {
    _ensureNotDisposed();
    try {
      final data = await _get(
        '/auth/check?uid=${Uri.encodeComponent(uid)}',
      );
      if (data == null) return UserCheckResult.newUser;
      return UserCheckResult.fromJson(data as Map<String, dynamic>);
    } on ApiServiceException catch (e) {
      if (!safeDefault) rethrow;
      if (kDebugMode) debugPrint('[ApiService] checkAuthUser error: $e');
      return UserCheckResult.newUser;
    }
  }

  // ── Account PIN (anti SIM-recycling) ───────────────────────────────────────

  /// Verifies the account PIN from this device. On success the backend trusts
  /// this install (X-Device-Id) and normal API access resumes.
  /// Returns null on success, or a reason key: 'wrong_pin' | 'locked' | 'no_pin'.
  Future<String?> verifyAccountPin(String pin) async {
    _ensureNotDisposed();
    final data = await _post('/auth/verify-pin', {'pin': pin});
    final map = data as Map<String, dynamic>;
    if (map['verified'] == true) return null;
    return map['reason'] as String? ?? 'wrong_pin';
  }

  /// Sets or changes the account PIN. [currentPin] required when changing.
  /// Returns null on success, or a reason key.
  Future<String?> setAccountPin(String pin, {String? currentPin}) async {
    _ensureNotDisposed();
    final data = await _post('/auth/pin', {
      'pin': pin,
      if (currentPin != null) 'currentPin': currentPin,
    });
    final map = data as Map<String, dynamic>;
    if (map['ok'] == true) return null;
    return map['reason'] as String? ?? 'wrong_pin';
  }

  /// Removes the account PIN. Returns null on success, or a reason key.
  Future<String?> removeAccountPin(String currentPin) async {
    _ensureNotDisposed();
    final data = await _post('/auth/pin/remove', {'currentPin': currentPin});
    final map = data as Map<String, dynamic>;
    if (map['ok'] == true) return null;
    return map['reason'] as String? ?? 'wrong_pin';
  }

  /// Forgotten PIN: starts the 7-day cooling period after which the PIN
  /// clears on the next verify attempt. Returns the clear date.
  Future<DateTime> requestPinReset() async {
    _ensureNotDisposed();
    final data = await _post('/auth/request-pin-reset', {});
    return DateTime.parse((data as Map<String, dynamic>)['resetAt'] as String);
  }

  // ── Professions ────────────────────────────────────────────────────────────

  /// Fetches the active profession list from GET /professions?lang=[lang].
  ///
  /// Returns an empty list on error — the caller
  /// (ProfessionsNotifier) falls back to [kDefaultProfessions].
  ///
  /// The endpoint is public (no auth required) and cached 24h client-side.
  Future<List<ProfessionModel>> getProfessions({String lang = 'fr'}) async {
    _ensureNotDisposed();
    try {
      final data = await _get(
        '/professions?lang=${Uri.encodeComponent(lang)}',
      );
      if (data == null) return const [];
      return (data as List)
          .map((e) => ProfessionModel.fromJson(
                (e as Map).cast<String, dynamic>(),
                lang: lang,
              ))
          .toList();
    } on ApiServiceException catch (e) {
      if (kDebugMode) debugPrint('[ApiService] getProfessions error: $e');
      return const [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES WORKER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<WorkerModel?> getWorker(String workerId) async {
    _ensureNotDisposed();
    if (workerId.trim().isEmpty) return null;
    final cached = _workerCache.get(workerId);
    if (cached != null) return cached;
    try {
      final data = await _get('/workers/$workerId');
      if (data == null) return null;
      final worker = WorkerModel.fromJson(data as Map<String, dynamic>);
      _workerCache.set(workerId, worker);
      return worker;
    } on ApiServiceException catch (e) {
      if (e.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  Future<void> setWorker(WorkerModel worker) => createOrUpdateWorker(worker);

  Future<void> createOrUpdateWorker(
    WorkerModel worker, {
    String? language,
    List<String>? verificationDocs,
  }) async {
    _ensureNotDisposed();

    final payload = <String, dynamic>{
      'id':    worker.id,
      'name':  worker.name,
      if (worker.email.isNotEmpty) 'email': worker.email,
      'role':  'worker',
      if (worker.profession?.isNotEmpty == true)
        'profession': worker.profession,
      'isOnline': worker.isOnline,
    };
    if (worker.phoneNumber.isNotEmpty)  payload['phoneNumber']     = worker.phoneNumber;
    if (worker.latitude != null)        payload['latitude']        = worker.latitude;
    if (worker.longitude != null)       payload['longitude']       = worker.longitude;
    if (worker.profileImageUrl != null) payload['profileImageUrl'] = worker.profileImageUrl;
    if (worker.fcmToken != null)        payload['fcmToken']        = worker.fcmToken;
    if (language != null && language.isNotEmpty) payload['language'] = language;
    // Optional verification documents → backend flips the account to 'pending'.
    if (verificationDocs != null && verificationDocs.isNotEmpty) {
      payload['verificationDocs'] = verificationDocs;
    }

    final data = await _post('/workers', payload);
    if (data != null) {
      final updated = WorkerModel.fromJson(data as Map<String, dynamic>);
      _workerCache.set(worker.id, updated);
    }
  }

  Future<void> updateWorkerLocation(
    String workerId, double latitude, double longitude, {
    String? cellId, int? wilayaCode, String? geoHash,
  }) async {
    _ensureNotDisposed();
    await _patch('/workers/$workerId/location', {
      'latitude':  latitude,
      'longitude': longitude,
      if (cellId     != null) 'cellId':     cellId,
      if (wilayaCode != null) 'wilayaCode': wilayaCode,
      if (geoHash    != null) 'geoHash':    geoHash,
    });
  }

  Future<void> updateWorkerStatus(String workerId, bool isOnline) async {
    _ensureNotDisposed();
    await _patch('/workers/$workerId/status', {'isOnline': isOnline});
    _workerCache.update(workerId, (w) => w.copyWith(isOnline: isOnline));
  }

  Future<void> updateWorkerOnlineStatus(String workerId, bool isOnline) =>
      updateWorkerStatus(workerId, isOnline);

  Future<void> updateWorkerFcmToken(String workerId, String token) async {
    _ensureNotDisposed();
    await _patch('/workers/$workerId/fcm-token', {'fcmToken': token});
  }

  Future<List<WorkerModel>> getWorkersInCell({
    required String cellId, String? serviceType, bool onlineOnly = false,
  }) async {
    _ensureNotDisposed();
    final q = StringBuffer('/location/cells/$cellId/workers?limit=50');
    if (serviceType != null) q.write('&serviceType=$serviceType');
    if (onlineOnly)           q.write('&onlineOnly=true');
    final data = await _get(q.toString());
    if (data == null) return [];
    return (data as List)
        .map((e) => WorkerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkerModel>> getWorkersInWilaya({
    required int wilayaCode, String? serviceType, bool onlineOnly = false,
  }) async {
    _ensureNotDisposed();
    final q = StringBuffer('/workers?wilayaCode=$wilayaCode&limit=50');
    if (serviceType != null) q.write('&profession=$serviceType');
    if (onlineOnly)           q.write('&isOnline=true');
    final data = await _get(q.toString());
    if (data == null) return [];
    return (data as List)
        .map((e) => WorkerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Stream for a single worker — WebSocket only is correct here.
  /// A single known worker is unlikely to be a seeded stub, and live
  /// position/status updates are the primary use case.
  Stream<WorkerModel?> streamWorker(String workerId) =>
      _realtime.streamWorker(workerId);

  // ── Bug 3 fix — hybrid worker streams ─────────────────────────────────────
  //
  // streamOnlineWorkersByWilayas:
  //   Fetches online workers for the given wilaya codes from REST on subscribe,
  //   then re-fetches on each WebSocket signal (workers:snapshot, worker:status,
  //   worker:location). For the common single-wilaya case (map view), the first
  //   wilayaCode is used for the REST query. Live updates from all supplied
  //   wilaya codes are handled by the underlying RealtimeService.
  //
  // Multi-wilaya note: the REST API supports a single wilayaCode parameter.
  // If multiple codes are supplied and workers from all are needed for the
  // initial state, call getWorkersInWilaya() for each code in parallel and
  // merge client-side, OR use streamOnlineWorkersUnscoped() which fetches
  // without a wilaya filter.
  Stream<List<WorkerModel>> streamOnlineWorkersByWilayas(List<int> wilayaCodes) {
    if (wilayaCodes.isEmpty) return const Stream.empty();

    // Build the REST query using the primary wilaya code.
    // The WS signal covers updates from all supplied codes.
    final primaryCode = wilayaCodes.first;
    return _hybridWorkerStream(
      httpQuery: '/workers?wilayaCode=$primaryCode&isOnline=true&limit=100',
      wsSignal:  _realtime.streamOnlineWorkersByWilayas(wilayaCodes),
    );
  }

  // streamOnlineWorkersUnscoped:
  //   Used when no wilaya filter is available (e.g. worker hasn't set location).
  //   REST query fetches all online workers up to [limit].
  Stream<List<WorkerModel>> streamOnlineWorkersUnscoped({int limit = 100}) =>
      _hybridWorkerStream(
        httpQuery: '/workers?isOnline=true&limit=$limit',
        wsSignal:  _realtime.streamOnlineWorkersUnscoped(limit: limit),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES SERVICE REQUEST
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> createServiceRequest(ServiceRequestEnhancedModel request) async {
    _ensureNotDisposed();
    final data = await _post('/service-requests', {
      'userId':          request.userId,
      'userName':        request.userName,
      'userPhone':       request.userPhone,
      'serviceType':     request.serviceType,
      'title':           request.title,
      'description':     request.description,
      'scheduledDate':   request.scheduledDate.toIso8601String(),
      'scheduledHour':   request.scheduledTime.hour,
      'scheduledMinute': request.scheduledTime.minute,
      'priority':        request.priority.name,
      'userLatitude':    request.userLatitude,
      'userLongitude':   request.userLongitude,
      'userAddress':     request.userAddress,
      'mediaUrls':       request.mediaUrls,
      if (request.budgetMin  != null) 'budgetMin':  request.budgetMin,
      if (request.budgetMax  != null) 'budgetMax':  request.budgetMax,
      if (request.cellId     != null) 'cellId':     request.cellId,
      if (request.wilayaCode != null) 'wilayaCode': request.wilayaCode,
      if (request.geoHash    != null) 'geoHash':    request.geoHash,
    });
    if (data != null) {
      final created = ServiceRequestEnhancedModel.fromJson(data as Map<String, dynamic>);
      _requestCache.set(created.id, created);
    }
  }

  Future<ServiceRequestEnhancedModel?> getServiceRequest(String requestId) async {
    _ensureNotDisposed();
    if (requestId.trim().isEmpty) return null;
    final cached = _requestCache.get(requestId);
    if (cached != null) return cached;
    try {
      final data = await _get('/service-requests/$requestId');
      if (data == null) return null;
      final req = ServiceRequestEnhancedModel.fromJson(data as Map<String, dynamic>);
      _requestCache.set(requestId, req);
      return req;
    } on ApiServiceException catch (e) {
      if (e.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  Future<void> updateServiceRequest(ServiceRequestEnhancedModel request) async {
    _ensureNotDisposed();
    // Send ONLY editable detail fields — NOT toMap(). The backend rejects
    // non-whitelisted keys (forbidNonWhitelisted) and ignores workflow fields.
    await _patch('/service-requests/${request.id}', request.toUpdatePayload());
    _requestCache.set(request.id, request);
  }

  Future<void> startJob(String requestId) async {
    _ensureNotDisposed();
    await _post('/service-requests/$requestId/start', {});
  }

  Future<void> completeJob({
    required String requestId, String? workerNotes, double? finalPrice,
  }) async {
    _ensureNotDisposed();
    await _post('/service-requests/$requestId/complete', {
      if (workerNotes != null) 'workerNotes': workerNotes,
      if (finalPrice  != null) 'finalPrice':  finalPrice,
    });
  }

  Future<void> cancelRequest(String requestId) async {
    _ensureNotDisposed();
    await _post('/service-requests/$requestId/cancel', {});
    _requestCache.clear();
  }

  /// Assigned worker declines a won job — the backend reopens the request
  /// for bids and notifies the client. NOT cancelRequest(), which is the
  /// owner-only endpoint (a worker calling it gets a 403).
  Future<void> declineJob(String requestId) async {
    _ensureNotDisposed();
    await _post('/service-requests/$requestId/decline', {});
    _requestCache.clear();
  }

  Future<void> submitClientRating({
    required String requestId, required int stars, String? comment,
  }) async {
    _ensureNotDisposed();
    await _post('/service-requests/$requestId/rate', {
      'stars': stars,
      if (comment != null) 'comment': comment,
    });
  }

  // ── Stream methods — HYBRID HTTP+WS ──────────────────────────────────────

  // Hybrid like its list siblings: initial HTTP fetch, then refetch on every
  // WS signal. The raw realtime stream is signal-only (emits null sentinels,
  // never a request) — consumers need the actual model.
  Stream<ServiceRequestEnhancedModel?> streamServiceRequest(String requestId) {
    late StreamController<ServiceRequestEnhancedModel?> ctrl;
    StreamSubscription<ServiceRequestEnhancedModel?>? wsSub;
    var hasData = false;

    Future<void> fetch() async {
      if (ctrl.isClosed) return;
      try {
        // Bypass the request cache — a WS signal means the doc just changed.
        final data = await _get('/service-requests/$requestId');
        if (ctrl.isClosed) return;
        if (data == null) {
          ctrl.add(null);
          return;
        }
        final req = ServiceRequestEnhancedModel.fromJson(
            (data as Map).cast<String, dynamic>());
        _requestCache.set(requestId, req);
        hasData = true;
        ctrl.add(req);
      } on ApiServiceException catch (e) {
        if (ctrl.isClosed) return;
        if (e.code == 'NOT_FOUND') {
          ctrl.add(null);
        } else if (!hasData) {
          ctrl.addError(e);
        }
      } catch (e) {
        // Keep last good value on transient re-fetch failure (see list streams).
        if (!ctrl.isClosed && !hasData) ctrl.addError(e);
      }
    }

    ctrl = StreamController<ServiceRequestEnhancedModel?>.broadcast(
      onListen: () {
        fetch();
        wsSub = _realtime.streamServiceRequest(requestId).listen(
          (_) => fetch(),
          onError: (Object e) {
            if (!ctrl.isClosed) ctrl.addError(e);
          },
          cancelOnError: false,
        );
      },
      onCancel: () {
        wsSub?.cancel();
        wsSub = null;
      },
    );

    return ctrl.stream;
  }

  Stream<List<ServiceRequestEnhancedModel>> streamUserServiceRequests(
      String userId) =>
      _hybridRequestStream(
        httpQuery: '/service-requests?userId=$userId&limit=50',
        wsSignal: _realtime.streamUserServiceRequests(userId),
      );

  Stream<List<ServiceRequestEnhancedModel>> streamWorkerServiceRequests(
      String workerId, {int? wilayaCode}) {
    final query = StringBuffer(
        '/service-requests?workerId=$workerId&limit=50'
        '&status=open,awaitingSelection,bidSelected,inProgress,completed');
    if (wilayaCode != null) query.write('&wilayaCode=$wilayaCode');
    return _hybridRequestStream(
      httpQuery: query.toString(),
      wsSignal:
          _realtime.streamWorkerServiceRequests(workerId, wilayaCode: wilayaCode),
    );
  }

  Stream<List<ServiceRequestEnhancedModel>> streamAvailableRequests({
    required List<int> wilayaCodes,
    required String serviceType,
  }) =>
      _hybridRequestStream(
        httpQuery: '/service-requests'
            '?wilayaCode=${wilayaCodes.join(',')}'
            '&serviceType=$serviceType'
            '&status=open,awaitingSelection'
            '&limit=50',
        wsSignal: _realtime.streamAvailableRequests(
            wilayaCodes: wilayaCodes, serviceType: serviceType),
      );

  Stream<List<ServiceRequestEnhancedModel>> streamWorkerActiveJobs(
      String workerId) =>
      _hybridRequestStream(
        httpQuery: '/service-requests?workerId=$workerId'
            '&status=bidSelected,inProgress&limit=20',
        wsSignal: _realtime.streamWorkerActiveJobs(workerId),
      );

  Stream<List<ServiceRequestEnhancedModel>> streamWorkerAssignedRequests(
      String workerId, {int limit = 30}) =>
      _hybridRequestStream(
        httpQuery: '/service-requests?workerId=$workerId&limit=$limit',
        wsSignal: _realtime.streamWorkerAssignedRequests(workerId, limit: limit),
      );

  // ── Bids — HYBRID ─────────────────────────────────────────────────────────

  Stream<List<WorkerBidModel>> streamBidsForRequest(String requestId) =>
      _hybridBidStream(
        httpQuery: '/bids?serviceRequestId=$requestId',
        wsSignal: _realtime.streamBidsForRequest(requestId),
      );

  Stream<List<WorkerBidModel>> streamWorkerBids(String workerId) =>
      _hybridBidStream(
        httpQuery: '/bids?workerId=$workerId&limit=50',
        wsSignal: _realtime.streamWorkerBids(workerId),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // createBid() — champs exacts de CreateBidDto uniquement
  //
  // PROBLÈME : bid.toMap() sérialisait TOUS les champs du modèle, y compris
  //   id, status, createdAt, expiresAt, acceptedAt — absents de CreateBidDto.
  //   ValidationPipe (forbidNonWhitelisted:true) → BadRequestException 400.
  //
  // SOLUTION : payload manuel avec les seuls champs de CreateBidDto.
  // ─────────────────────────────────────────────────────────────────────────
  Future<WorkerBidModel> createBid(WorkerBidModel bid) async {
    _ensureNotDisposed();

    final payload = <String, dynamic>{
      'serviceRequestId':    bid.serviceRequestId,
      'workerId':            bid.workerId,
      'workerName':          bid.workerName,
      'workerAverageRating': bid.workerAverageRating,
      'workerJobsCompleted': bid.workerJobsCompleted,
      'proposedPrice':       bid.proposedPrice,
      'estimatedMinutes':    bid.estimatedMinutes,
      'availableFrom':       bid.availableFrom.toIso8601String(),
    };

    if (bid.workerProfileImageUrl != null) {
      payload['workerProfileImageUrl'] = bid.workerProfileImageUrl;
    }
    if (bid.message?.isNotEmpty == true) {
      payload['message'] = bid.message;
    }
    if (bid.expiresAt != null) {
      payload['expiresAt'] = bid.expiresAt!.toIso8601String();
    }

    final data = await _post('/bids', payload);
    return WorkerBidModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> acceptBidTransaction({
    required String requestId, required String bidId,
    required String workerId, required String workerName, required double agreedPrice,
  }) async {
    _ensureNotDisposed();
    await _post('/bids/$bidId/accept', {'requestId': requestId});
  }

  Future<void> withdrawBid({required String bidId, required String requestId}) async {
    _ensureNotDisposed();
    await _post('/bids/$bidId/withdraw', {});
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> createNotification(NotificationModel notification) async {
    _ensureNotDisposed();
    _logInfo('createNotification: no-op (server-push only in new stack)');
  }

  /// GET /notifications — the authenticated user's inbox (newest first).
  Future<List<NotificationModel>> fetchNotifications({int limit = 50}) async {
    _ensureNotDisposed();
    final data = await _get('/notifications?limit=$limit');
    if (data == null) return const [];
    return (data as List)
        .map((e) => NotificationModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    _ensureNotDisposed();
    await _patch('/notifications/$id/read', const {});
  }

  Future<void> markAllNotificationsRead() async {
    _ensureNotDisposed();
    await _patch('/notifications/read-all', const {});
  }

  // ── Geographic cells ───────────────────────────────────────────────────────

  Future<void> saveCell(GeographicCell cell) async {
    _ensureNotDisposed();
    _logInfo('saveCell: no-op (server-side only)');
  }

  Future<GeographicCell?> getCell(String cellId) async {
    _ensureNotDisposed();
    try {
      final data = await _get('/location/cells/$cellId/adjacent');
      if (data == null) return null;
      final adjacentIds = (data['adjacentCellIds'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      final parts = cellId.split('_');
      if (parts.length != 3) return null;
      return GeographicCell(
        id:              cellId,
        wilayaCode:      int.tryParse(parts[0]) ?? 0,
        centerLat:       double.tryParse(parts[1]) ?? 0,
        centerLng:       double.tryParse(parts[2]) ?? 0,
        radius:          5.0,
        adjacentCellIds: adjacentIds,
      );
    } on ApiServiceException catch (e) {
      if (e.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  Future<List<GeographicCell>> getCellsInWilaya(int wilayaCode) async => [];

  // ── Création atomique de profil ────────────────────────────────────────────

  Future<void> atomicCreateUserProfile({UserModel? user, WorkerModel? worker}) async {
    _ensureNotDisposed();
    if (worker != null) await createOrUpdateWorker(worker);
    if (user   != null) await createOrUpdateUser(user);
  }

  // ── Gestion du cache ───────────────────────────────────────────────────────

  void startCacheCleanup() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _userCache.cleanExpired();
      _workerCache.cleanExpired();
      _requestCache.cleanExpired();
    });
  }

  void cacheUser(String userId, UserModel user)      => _userCache.set(userId, user);
  void cacheWorker(String workerId, WorkerModel w)   => _workerCache.set(workerId, w);

  void cleanExpiredCache() {
    _userCache.cleanExpired();
    _workerCache.cleanExpired();
    _requestCache.cleanExpired();
  }

  _ApiDirectClient get firestore => _ApiDirectClient(this);

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cacheCleanupTimer?.cancel();
    _userCache.clear();
    _workerCache.clear();
    _requestCache.clear();
    _http.close();
    _logInfo('ApiService disposed');
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw const ApiServiceException(
          'ApiService has been disposed', code: 'SERVICE_DISPOSED');
    }
  }

  void _logInfo(String m) {
    if (kDebugMode) debugPrint('[ApiService] $m');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ApiDirectClient shim — rétrocompatibilité pour les call sites existants
// ─────────────────────────────────────────────────────────────────────────────

class _ApiDirectClient {
  final ApiService _api;
  const _ApiDirectClient(this._api);

  _CollectionRef collection(String name) => _CollectionRef(_api, name);
}

class _CollectionRef {
  final ApiService _api;
  final String     _collection;
  const _CollectionRef(this._api, this._collection);

  _DocRef doc(String id) => _DocRef(_api, _collection, id);

  _QueryRef where(String field, {dynamic isEqualTo, bool? isNull}) =>
      _QueryRef(_api, _collection, field, isEqualTo: isEqualTo, isNull: isNull);
}

class _DocRef {
  final ApiService _api;
  final String     _collection;
  final String     _id;
  const _DocRef(this._api, this._collection, this._id);

  Future<_DocSnapshot> get() async {
    try {
      final data = await _api._get('/$_collection/$_id');
      return _DocSnapshot(id: _id, data: data as Map<String, dynamic>?, exists: data != null);
    } on ApiServiceException catch (e) {
      if (e.code == 'NOT_FOUND') return _DocSnapshot(id: _id, data: null, exists: false);
      rethrow;
    }
  }

  Future<void> set(Map<String, dynamic> data, [dynamic options]) async {
    await _api._post('/$_collection', {'id': _id, ...data});
  }

  Future<void> update(Map<String, dynamic> data) async {
    await _api._patch('/$_collection/$_id', data);
  }

  Future<void> delete() async {
    if (kDebugMode) {
      debugPrint('[ApiDirectClient] delete not fully implemented for $_collection/$_id');
    }
  }
}

class _DocSnapshot {
  final String               id;
  final Map<String, dynamic>? _data;
  final bool                 exists;

  const _DocSnapshot({required this.id, required Map<String, dynamic>? data, required this.exists})
      : _data = data;

  Map<String, dynamic>? data() => _data;
}

class _QueryRef {
  final ApiService _api;
  final String     _collection;
  final String     _field;
  final dynamic    _isEqualTo;
  final bool?      _isNull;

  const _QueryRef(this._api, this._collection, this._field,
      {dynamic isEqualTo, bool? isNull})
      : _isEqualTo = isEqualTo,
        _isNull    = isNull;

  _QueryRef where(String field, {dynamic isEqualTo, bool? isNull}) =>
      _QueryRef(_api, _collection, field, isEqualTo: isEqualTo, isNull: isNull);

  _QueryRef limit(int n) => this;

  Future<_QuerySnapshot> get() async {
    final q = StringBuffer('/$_collection?');
    if (_isEqualTo != null) {
      q.write('$_field=${Uri.encodeComponent(_isEqualTo.toString())}&');
    }
    q.write('limit=50');
    final data = await _api._get(q.toString());
    if (data == null) return _QuerySnapshot([]);
    final docs = (data as List).map((e) {
      final m  = e as Map<String, dynamic>;
      final id = (m['_id'] ?? m['id'] ?? '') as String;
      return _DocSnapshot(id: id, data: m, exists: true);
    }).toList();
    return _QuerySnapshot(docs);
  }
}

class _QuerySnapshot {
  final List<_DocSnapshot> docs;
  const _QuerySnapshot(this.docs);
}
