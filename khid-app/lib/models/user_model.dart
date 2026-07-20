// lib/models/user_model.dart
//
// ARCHITECTURE — COLLECTION UNIFIÉE
// ────────────────────────────────────────────────────────────────────────────
// Le backend a fusionné les collections `users` et `workers` en une seule
// collection `users`, discriminée par le champ `role`.  Ce modèle reflète
// cette réalité : un seul objet Dart représente un client ET un travailleur.
//
// CHAMPS WORKER
// Les champs spécifiques aux travailleurs (profession, isOnline, averageRating…)
// sont présents dans tous les documents mais avec des valeurs neutres pour les
// clients (null / false / 0). Cela garantit qu'un document client ne satisfera
// jamais une requête worker-ciblée côté serveur.
//
// MIGRATION
// WorkerModel est maintenant un alias de type dans worker_model.dart.
// Tous les call sites existants compilent sans aucune modification.

import 'package:equatable/equatable.dart';

// Sentinel pour distinguer "champ absent" de "champ explicitement null"
// dans copyWith. Technique éprouvée — ne pas remplacer par null.
const _kUndef = Object();

// ─────────────────────────────────────────────────────────────────────────────
// UserModel
// ─────────────────────────────────────────────────────────────────────────────

class UserModel extends Equatable {
  // ── Identité ─────────────────────────────────────────────────────────────
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  /// Discriminateur de collection : 'client' | 'worker'
  final String role;

  // ── Localisation (commune) ────────────────────────────────────────────────
  final double? latitude;
  final double? longitude;
  final DateTime lastUpdated;
  final String? cellId;
  final int? wilayaCode;
  final String? geoHash;
  final DateTime? lastCellUpdate;

  // ── Médias / push (communs) ───────────────────────────────────────────────
  final String? profileImageUrl;
  final String? fcmToken;

  // ── Spécifiques au travailleur ────────────────────────────────────────────
  // Valeurs neutres pour les clients : null / false / 0 / 0.7
  // → un document client ne satisfera jamais isOnline=true ou profession≠null.

  /// Clé de métier (null pour les clients).
  final String? profession;

  /// Statut en ligne — pertinent uniquement pour les travailleurs.
  final bool isOnline;

  /// Note bayésienne (0–5). Initialisée à 0.0 pour les clients.
  final double averageRating;

  /// Nombre de notes reçues.
  final int ratingCount;

  /// Somme cumulée des étoiles — permet le recalcul bayésien sans historique.
  final int ratingSum;

  /// Nombre de missions accomplies.
  final int jobsCompleted;

  /// Taux de réponse aux offres (0–1). Valeur a priori : 0.7.
  final double responseRate;

  /// Horodatage de la dernière déconnexion — utilisé pour le tri par récence.
  final DateTime? lastActiveAt;

  // ── Abonnement de visibilité (worker) ──────────────────────────────────────
  /// Vérifié par un admin (documents approuvés). Requis pour l'accès B2B.
  final bool isVerified;

  /// Abonnement de visibilité actif. Faux pour les clients.
  final bool subscriptionActive;

  /// Expiration de l'abonnement. null = jamais abonné.
  final DateTime? subscriptionUntil;

  /// Pack d'abonnement : 'basic' 500 / 'pro' 1000 / 'business' 1500 /
  /// 'expert' 2500 / 'custom' (curseurs 500–1500). null = jamais abonné.
  final String? subscriptionTier;

  // ── Entitlements du pack (écrits par le backend à l'activation) ─────────────
  /// Prix du pack en DA/mois. Packs < 1000 : invisibles samedi & dimanche.
  final int? subscriptionPrice;

  /// Quota quotidien de visibilité en secondes. null = illimité.
  final int? dailyQuotaSeconds;

  /// Quota mensuel de bids. null = illimité, 0 = pas d'accès bid (Basic).
  final int? monthlyBidQuota;

  /// Business/Expert : boost de classement + badge « Pro ».
  final bool searchPriority;

  // ── Compteur de bids (bucket mensuel) ────────────────────────────────────────
  /// Bids consommés dans [bidMonth].
  final int bidsUsed;

  /// Mois local (YYYY-MM) auquel appartient [bidsUsed].
  final String? bidMonth;

  // ── Compteur d'utilisation (temps en ligne, par jour) ───────────────────────
  /// Temps en ligne cumulé pour [usageDay], en secondes. Remis à zéro à 00:00.
  final int usageSeconds;

  /// Jour local (YYYY-MM-DD) auquel appartient [usageSeconds].
  final String? usageDay;

  /// Instant du dernier passage en ligne. null si hors ligne.
  final DateTime? onlineSince;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.role = 'client',
    this.latitude,
    this.longitude,
    required this.lastUpdated,
    this.cellId,
    this.wilayaCode,
    this.geoHash,
    this.lastCellUpdate,
    this.profileImageUrl,
    this.fcmToken,
    // Valeurs neutres par défaut — sûres pour les clients
    this.profession,
    this.isOnline = false,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.ratingSum = 0,
    this.jobsCompleted = 0,
    this.responseRate = 0.7,
    this.lastActiveAt,
    this.isVerified = false,
    this.subscriptionActive = false,
    this.subscriptionUntil,
    this.subscriptionTier,
    this.subscriptionPrice,
    this.dailyQuotaSeconds,
    this.monthlyBidQuota,
    this.searchPriority = false,
    this.bidsUsed = 0,
    this.bidMonth,
    this.usageSeconds = 0,
    this.usageDay,
    this.onlineSince,
  });

  // ── Getters calculés ──────────────────────────────────────────────────────

  /// Vrai si ce document représente un travailleur.
  bool get isWorker => role == 'worker';

  /// Vrai si l'abonnement de visibilité est actif et non expiré.
  bool get isSubscribed =>
      subscriptionActive &&
      (subscriptionUntil == null || subscriptionUntil!.isAfter(DateTime.now()));

  /// Clé de jour local YYYY-MM-DD — bucket du compteur quotidien.
  static String dayKey(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  /// Clé de mois local YYYY-MM — bucket du compteur de bids.
  static String monthKey(DateTime d) => dayKey(d).substring(0, 7);

  /// Vrai quand le quota du jour est épuisé — le backend masque alors le
  /// worker de la recherche et de la carte jusqu'à 00:00.
  bool quotaExhaustedAt(DateTime now) {
    final q = dailyQuotaSeconds;
    return q != null && usageSecondsAt(now) >= q;
  }

  /// Vrai si le pack inclut l'accès bid (quota null = illimité, 0 = aucun).
  bool get canBid => monthlyBidQuota != 0;

  /// Bids consommés CE MOIS-CI — un bucket d'un autre mois vaut 0.
  int bidsUsedAt(DateTime now) => bidMonth == monthKey(now) ? bidsUsed : 0;

  /// Bids restants ce mois-ci. null = illimité.
  int? bidsRemainingAt(DateTime now) {
    final q = monthlyBidQuota;
    if (q == null) return null;
    final left = q - bidsUsedAt(now);
    return left > 0 ? left : 0;
  }

  /// Temps en ligne AUJOURD'HUI à l'instant [now] : bucket du jour + session en
  /// cours si en ligne. Le compteur repart de zéro à 00:00 — un bucket d'un
  /// autre jour vaut 0, et une session à cheval sur minuit n'est comptée qu'à
  /// partir de minuit.
  int usageSecondsAt(DateTime now) {
    final today = dayKey(now);
    var total = (usageDay == today) ? usageSeconds : 0;
    if (isOnline && onlineSince != null) {
      final local = now.toLocal();
      final midnight = DateTime(local.year, local.month, local.day);
      final start = onlineSince!.isAfter(midnight) ? onlineSince! : midnight;
      final live = now.difference(start).inSeconds;
      if (live > 0) total += live;
    }
    return total;
  }

  /// Vrai si ce document représente un client.
  bool get isClient => role == 'client';

  /// Jours depuis la dernière activité. 0 si le worker est en ligne ou inconnu.
  int get daysSinceActive {
    if (lastActiveAt == null) return 0;
    return DateTime.now().difference(lastActiveAt!).inDays.clamp(0, 9999);
  }

  // ── Désérialisation ───────────────────────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id:          id,
      name:        map['name']        as String? ?? '',
      email:       map['email']       as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      role:        map['role']        as String? ?? 'client',
      latitude:    (map['latitude']   as num?)?.toDouble(),
      longitude:   (map['longitude']  as num?)?.toDouble(),
      lastUpdated:    _parseDate(map['lastUpdated']),
      cellId:         map['cellId']          as String?,
      wilayaCode:     map['wilayaCode']      as int?,
      geoHash:        map['geoHash']         as String?,
      lastCellUpdate: _parseDateOrNull(map['lastCellUpdate']),
      profileImageUrl: map['profileImageUrl'] as String?,
      fcmToken:        map['fcmToken']        as String?,
      // Champs worker — valeurs neutres si absents (documents clients)
      profession:    map['profession']    as String?,
      isOnline:      map['isOnline']      as bool?   ?? false,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount:   map['ratingCount']   as int?    ?? 0,
      ratingSum:     map['ratingSum']     as int?    ?? 0,
      jobsCompleted: map['jobsCompleted'] as int?    ?? 0,
      responseRate:  (map['responseRate'] as num?)?.toDouble() ?? 0.7,
      lastActiveAt:  _parseDateOrNull(map['lastActiveAt']),
      isVerified:         map['isVerified'] as bool? ?? false,
      subscriptionActive: map['subscriptionActive'] as bool? ?? false,
      subscriptionUntil:  _parseDateOrNull(map['subscriptionUntil']),
      subscriptionTier:   map['subscriptionTier'] as String?,
      subscriptionPrice:  (map['subscriptionPrice'] as num?)?.toInt(),
      dailyQuotaSeconds:  (map['dailyQuotaSeconds'] as num?)?.toInt(),
      monthlyBidQuota:    (map['monthlyBidQuota'] as num?)?.toInt(),
      searchPriority:     map['searchPriority'] as bool? ?? false,
      bidsUsed:      map['bidsUsed']     as int? ?? 0,
      bidMonth:      map['bidMonth']     as String?,
      usageSeconds:  map['usageSeconds'] as int? ?? 0,
      usageDay:      map['usageDay']     as String?,
      onlineSince:   _parseDateOrNull(map['onlineSince']),
    );
  }

  /// Accepte les réponses NestJS où l'id est sous `_id` ou `id`.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id']) as String? ?? '';
    return UserModel.fromMap(json, id);
  }

  Map<String, dynamic> toMap() => {
    'name':            name,
    'email':           email,
    'phoneNumber':     phoneNumber,
    'role':            role,
    'latitude':        latitude,
    'longitude':       longitude,
    'lastUpdated':     lastUpdated.toIso8601String(),
    'cellId':          cellId,
    'wilayaCode':      wilayaCode,
    'geoHash':         geoHash,
    'lastCellUpdate':  lastCellUpdate?.toIso8601String(),
    'profileImageUrl': profileImageUrl,
    'fcmToken':        fcmToken,
    'profession':      profession,
    'isOnline':        isOnline,
    'averageRating':   averageRating,
    'ratingCount':     ratingCount,
    'ratingSum':       ratingSum,
    'jobsCompleted':   jobsCompleted,
    'responseRate':    responseRate,
    'lastActiveAt':    lastActiveAt?.toIso8601String(),
    'isVerified':         isVerified,
    'subscriptionActive': subscriptionActive,
    'subscriptionUntil':  subscriptionUntil?.toIso8601String(),
    'subscriptionTier':   subscriptionTier,
    'subscriptionPrice':  subscriptionPrice,
    'dailyQuotaSeconds':  dailyQuotaSeconds,
    'monthlyBidQuota':    monthlyBidQuota,
    'searchPriority':     searchPriority,
    'bidsUsed':           bidsUsed,
    'bidMonth':           bidMonth,
    'usageSeconds':       usageSeconds,
    'usageDay':           usageDay,
    'onlineSince':        onlineSince?.toIso8601String(),
  };

  // ── copyWith ──────────────────────────────────────────────────────────────
  // Sentinel _kUndef permet de distinguer "ne pas changer" de "mettre à null".
  // Pattern standard pour les champs nullable — ne pas simplifier.

  UserModel copyWith({
    String?   id,
    String?   name,
    String?   email,
    String?   phoneNumber,
    String?   role,
    Object?   latitude        = _kUndef,
    Object?   longitude       = _kUndef,
    DateTime? lastUpdated,
    Object?   cellId          = _kUndef,
    Object?   wilayaCode      = _kUndef,
    Object?   geoHash         = _kUndef,
    Object?   lastCellUpdate  = _kUndef,
    Object?   profileImageUrl = _kUndef,
    Object?   fcmToken        = _kUndef,
    Object?   profession      = _kUndef,
    bool?     isOnline,
    double?   averageRating,
    int?      ratingCount,
    int?      ratingSum,
    int?      jobsCompleted,
    double?   responseRate,
    Object?   lastActiveAt    = _kUndef,
    bool?     isVerified,
    bool?     subscriptionActive,
    Object?   subscriptionUntil = _kUndef,
    Object?   subscriptionTier  = _kUndef,
    Object?   subscriptionPrice = _kUndef,
    Object?   dailyQuotaSeconds = _kUndef,
    Object?   monthlyBidQuota   = _kUndef,
    bool?     searchPriority,
    int?      bidsUsed,
    Object?   bidMonth          = _kUndef,
    int?      usageSeconds,
    Object?   usageDay          = _kUndef,
    Object?   onlineSince       = _kUndef,
  }) {
    return UserModel(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      email:       email       ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role:        role        ?? this.role,
      latitude: identical(latitude, _kUndef)
          ? this.latitude        : latitude        as double?,
      longitude: identical(longitude, _kUndef)
          ? this.longitude       : longitude       as double?,
      lastUpdated:    lastUpdated    ?? this.lastUpdated,
      cellId: identical(cellId, _kUndef)
          ? this.cellId          : cellId          as String?,
      wilayaCode: identical(wilayaCode, _kUndef)
          ? this.wilayaCode      : wilayaCode      as int?,
      geoHash: identical(geoHash, _kUndef)
          ? this.geoHash         : geoHash         as String?,
      lastCellUpdate: identical(lastCellUpdate, _kUndef)
          ? this.lastCellUpdate  : lastCellUpdate  as DateTime?,
      profileImageUrl: identical(profileImageUrl, _kUndef)
          ? this.profileImageUrl : profileImageUrl as String?,
      fcmToken: identical(fcmToken, _kUndef)
          ? this.fcmToken        : fcmToken        as String?,
      profession: identical(profession, _kUndef)
          ? this.profession      : profession      as String?,
      isOnline:      isOnline      ?? this.isOnline,
      averageRating: averageRating ?? this.averageRating,
      ratingCount:   ratingCount   ?? this.ratingCount,
      ratingSum:     ratingSum     ?? this.ratingSum,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      responseRate:  responseRate  ?? this.responseRate,
      lastActiveAt: identical(lastActiveAt, _kUndef)
          ? this.lastActiveAt    : lastActiveAt    as DateTime?,
      isVerified:         isVerified         ?? this.isVerified,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
      subscriptionUntil: identical(subscriptionUntil, _kUndef)
          ? this.subscriptionUntil : subscriptionUntil as DateTime?,
      subscriptionTier: identical(subscriptionTier, _kUndef)
          ? this.subscriptionTier : subscriptionTier as String?,
      subscriptionPrice: identical(subscriptionPrice, _kUndef)
          ? this.subscriptionPrice : subscriptionPrice as int?,
      dailyQuotaSeconds: identical(dailyQuotaSeconds, _kUndef)
          ? this.dailyQuotaSeconds : dailyQuotaSeconds as int?,
      monthlyBidQuota: identical(monthlyBidQuota, _kUndef)
          ? this.monthlyBidQuota : monthlyBidQuota as int?,
      searchPriority: searchPriority ?? this.searchPriority,
      bidsUsed: bidsUsed ?? this.bidsUsed,
      bidMonth: identical(bidMonth, _kUndef)
          ? this.bidMonth : bidMonth as String?,
      usageSeconds: usageSeconds ?? this.usageSeconds,
      usageDay: identical(usageDay, _kUndef)
          ? this.usageDay : usageDay as String?,
      onlineSince: identical(onlineSince, _kUndef)
          ? this.onlineSince : onlineSince as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    id, name, email, phoneNumber, role,
    latitude, longitude, lastUpdated,
    cellId, wilayaCode, geoHash, lastCellUpdate,
    profileImageUrl, fcmToken,
    profession, isOnline, averageRating, ratingCount,
    ratingSum, jobsCompleted, responseRate, lastActiveAt,
    isVerified, subscriptionActive, subscriptionUntil, subscriptionTier,
    subscriptionPrice, dailyQuotaSeconds, monthlyBidQuota, searchPriority,
    bidsUsed, bidMonth,
    usageSeconds, usageDay, onlineSince,
  ];

  @override
  String toString() =>
      'UserModel(id: $id, role: $role, name: $name'
      '${isWorker ? ", profession: $profession, isOnline: $isOnline" : ""})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de parsing de date
// Acceptent : DateTime, String ISO-8601, Map Firestore {_seconds, _nanoseconds}
// ─────────────────────────────────────────────────────────────────────────────

DateTime _parseDate(dynamic value) {
  if (value == null)         return DateTime.now();
  if (value is DateTime)     return value;
  if (value is String)       return DateTime.tryParse(value) ?? DateTime.now();
  if (value is Map) {
    final s = value['_seconds'] as int?;
    if (s != null) return DateTime.fromMillisecondsSinceEpoch(s * 1000);
  }
  return DateTime.now();
}

DateTime? _parseDateOrNull(dynamic value) {
  if (value == null)         return null;
  if (value is DateTime)     return value;
  if (value is String)       return DateTime.tryParse(value);
  if (value is Map) {
    final s = value['_seconds'] as int?;
    if (s != null) return DateTime.fromMillisecondsSinceEpoch(s * 1000);
  }
  return null;
}
