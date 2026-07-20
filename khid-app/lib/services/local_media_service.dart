// lib/services/local_media_service.dart
//
// MIGRATION v15 — NestJS proxy MinIO → Cloudinary direct
//
// CHANGEMENT D'ARCHITECTURE :
//   AVANT (MinIO) : le backend retournait un `url` temporaire (dépendant du
//   tunnel Cloudflare) ET un `storedPath` durable. Il fallait persister
//   storedPath et reconstruire l'URL via MediaPathHelper.toUrl() à chaque
//   affichage.
//
//   APRÈS (Cloudinary) : le backend retourne un `url` Cloudinary qui EST
//   déjà permanent (CDN, ne dépend d'aucun domaine de notre infra).
//
//   ⚠️ NOUVELLE RÈGLE — INVERSE DE L'ANCIENNE :
//     ✅ PERSISTER  : result.url        (permanent, affichable directement)
//     ℹ️  storedPath : utile uniquement si on veut permettre la suppression
//                      plus tard (DELETE /media/object/<storedPath>) — pas
//                      nécessaire pour l'affichage.
//
// RÉTROCOMPATIBILITÉ :
//   CloudinaryServiceException est conservée (même nom, même interface) pour
//   ne pas casser les call sites existants qui importent cette exception.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
export 'local_media_service.dart' show CloudinaryServiceException;

// ── UploadResult ──────────────────────────────────────────────────────────────

/// Résultat d'un upload vers le backend NestJS / Cloudinary.
///
/// USAGE :
///   ```dart
///   final result = await localMediaService.uploadImage(file);
///
///   // ✅ Persister en base de données (URL permanente Cloudinary) :
///   mediaUrls.add(result.url);
///
///   // ✅ Afficher directement (même URL, aucune reconstruction nécessaire) :
///   Image.network(result.url)
///   ```
class UploadResult {
  /// URL Cloudinary complète et PERMANENTE — CDN public, ne dépend d'aucun
  /// domaine de notre infrastructure (contrairement à l'ancien tunnel
  /// Cloudflare avec MinIO).
  ///
  /// ✅ PERSISTER CE CHAMP en base de données.
  /// ✅ Utilisable directement dans Image.network() / VideoPlayer, etc.
  final String url;

  /// Identifiant interne Cloudinary : "resourceType/folder/userId/timestamp_uuid".
  /// Ex: "image/profile-images/abc123/1719312345678_550e8400"
  ///
  /// Utile UNIQUEMENT si on veut implémenter la suppression du fichier plus
  /// tard (DELETE /media/object/<storedPath>). Pas nécessaire pour l'affichage.
  final String storedPath;

  const UploadResult({
    required this.url,
    required this.storedPath,
  });

  @override
  String toString() => 'UploadResult(url: $url, storedPath: $storedPath)';
}

// ── Exception (rétrocompatibilité) ────────────────────────────────────────────
// Le nom CloudinaryServiceException est conservé pour ne pas casser les imports
// existants dans MediaService et autres call sites.

class CloudinaryServiceException implements Exception {
  final String  message;
  final String? code;
  final dynamic originalError;

  const CloudinaryServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'CloudinaryServiceException: $message${code != null ? ' ($code)' : ''}';
}

// ── LocalMediaService ─────────────────────────────────────────────────────────

class LocalMediaService {
  final String      _baseUrl;
  final http.Client _http;

  static const Duration _uploadTimeout = Duration(minutes: 5);

  LocalMediaService({required String baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _http = httpClient ?? http.Client();

  Future<String?> _getToken() async =>
      FirebaseAuth.instance.currentUser?.getIdToken();

  // ── Core upload ─────────────────────────────────────────────────────────────

  /// Upload [file] vers [endpoint], retourne un [UploadResult].
  ///
  /// Le backend NestJS répond avec :
  /// ```json
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "url":        "https://res.cloudinary.com/df9mahgkj/image/upload/v.../profile-images/abc123/170000_uuid.jpg",
  ///     "key":        "170000_uuid",
  ///     "storedPath": "image/profile-images/abc123/170000_uuid"
  ///   }
  /// }
  /// ```
  Future<UploadResult> _upload(File file, String endpoint) async {
    if (!await file.exists()) {
      throw CloudinaryServiceException(
        'File does not exist: ${file.path}',
        code: 'FILE_NOT_FOUND',
      );
    }
    final fileSize = await file.length();
    if (fileSize == 0) {
      throw CloudinaryServiceException('File is empty', code: 'EMPTY_FILE');
    }

    final token   = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$endpoint'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final streamed = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detail = '';
        try {
          final body = jsonDecode(response.body);
          detail = (body['message'] as String?) ?? '';
        } catch (_) {}
        throw CloudinaryServiceException(
          'Upload failed (${response.statusCode})${detail.isNotEmpty ? ': $detail' : ''}',
          code: 'UPLOAD_FAILED',
        );
      }

      // Parser la réponse — le ResponseInterceptor NestJS enveloppe en
      // { success: true, data: { url, key, storedPath } }
      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> data;

      if (decoded is Map &&
          decoded['success'] == true &&
          decoded.containsKey('data')) {
        data = (decoded['data'] as Map).cast<String, dynamic>();
      } else if (decoded is Map) {
        data = decoded.cast<String, dynamic>();
      } else {
        throw const CloudinaryServiceException(
          'Unexpected response format',
          code: 'PARSE_ERROR',
        );
      }

      final url        = data['url']        as String? ?? '';
      final storedPath = data['storedPath'] as String? ?? '';

      if (url.isEmpty) {
        throw const CloudinaryServiceException(
          'No url in upload response',
          code: 'PARSE_ERROR',
        );
      }

      if (kDebugMode) {
        debugPrint('[LocalMediaService] Upload success: url=$url');
      }

      return UploadResult(url: url, storedPath: storedPath);
    } on CloudinaryServiceException {
      rethrow;
    } catch (e) {
      throw CloudinaryServiceException(
        'Upload error: ${e.toString()}',
        code: 'UPLOAD_ERROR',
        originalError: e,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // API publique
  // ══════════════════════════════════════════════════════════════════════════

  /// Upload une image (JPEG / PNG / WebP, max 10 MB).
  /// Retourne un [UploadResult]. Persister [UploadResult.url] en base.
  Future<UploadResult> uploadImage(File file, {String? folder}) =>
      _upload(file, '/media/upload/image');

  /// Upload une vidéo (MP4 / MOV…, max 100 MB).
  /// Retourne un [UploadResult]. Persister [UploadResult.url] en base.
  Future<UploadResult> uploadVideo(
    File file, {
    String? folder,
    int?    maxDurationSeconds,
  }) =>
      _upload(file, '/media/upload/video');

  /// Upload un fichier audio (M4A / WAV / MP3…, max 50 MB).
  /// Retourne un [UploadResult]. Persister [UploadResult.url] en base.
  Future<UploadResult> uploadAudio(File file, {String? folder}) =>
      _upload(file, '/media/upload/audio');

  /// Upload un document de vérification (PDF ou image, max 10 MB).
  /// Retourne un [UploadResult]. Persister [UploadResult.url] en base.
  Future<UploadResult> uploadDocument(File file, {String? folder}) =>
      _upload(file, '/media/upload/document');

  // ── Stubs rétrocompatibles ─────────────────────────────────────────────────

  /// @deprecated Cloudinary ne nécessite pas de transformation côté app —
  /// l'URL retournée est déjà finale. Retourne la valeur telle quelle.
  String getOptimizedImageUrl(
    String publicIdOrStoredPath, {
    int?   width,
    int?   height,
    String crop    = 'fill',
    int    quality = 80,
    String format  = 'auto',
  }) =>
      publicIdOrStoredPath;

  /// @deprecated Idem — conservé pour compatibilité de signature.
  String getVideoUrl(
    String publicIdOrStoredPath, {
    int?   width,
    int?   height,
    String format = 'mp4',
  }) =>
      publicIdOrStoredPath;

  /// Suppression gérée côté serveur via DELETE /media/object/*.
  /// Ce stub retourne toujours false — utiliser ApiService.deleteMedia()
  /// avec UploadResult.storedPath si la suppression est implémentée.
  Future<bool> deleteFile(String publicId) async => false;

  void dispose() => _http.close();
}
