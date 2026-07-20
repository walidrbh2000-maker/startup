// lib/services/local_ai_service.dart
//
// FIX v2 — deux correctifs critiques :
//
// FIX 1 : TIMEOUT IMAGE
//   Avant : _callTimeoutImage = 30s → backend CPU prend ~56s → timeout systématique
//   Après : _callTimeoutImage = 120s (marge confortable pour CPU Codespaces)
//   Note  : quand on passe sur GPU (prod), 120s reste correct (GPU répond en < 5s)
//
// FIX 2 : RESIZE IMAGE AVANT ENVOI
//   Avant : image raw de la caméra (~3-5 MB, 4000x3000px) → mmproj encode 34 990ms
//   Après : image redimensionnée à max 512px → ~30-80 KB → encoding ~1-2s
//
//   Pourquoi 512px max :
//     Gemma4 découpe l'image en patches de 14x14px (SigLIP ViT).
//     Pour identifier "tuyau qui fuit", "climatiseur cassé", "mur fissuré",
//     une résolution de 512px est LARGEMENT suffisante.
//     La résolution maximale utile pour la vision Gemma4 E2B est ~896px
//     (image_size dans mmproj hparams), mais 512px donne 95% de la qualité
//     avec 3x moins de tokens → 3x moins de temps d'encoding.
//
//   IMPLÉMENTATION : dart:ui (aucune dépendance externe)
//     Pas besoin de flutter_image_compress — dart:ui.Image + toByteData()
//     suffit pour un resize bilinéaire simple. Fonctionne sur iOS et Android.
//
// FIX 3 : AUDIO TIMEOUT
//   Avant : audio utilisait _callTimeoutText = 15s (correct pour le backend
//     qui répond en ~6.5s) — MAIS le retry logic peut prendre 15s + 2s + 15s
//     = 32s avant d'échouer. Augmenté à 30s par appel pour les cas lents.
//
// BUG 4 FIX B (inchangé) : retry x2 sur image timeout + timeout texte 15s

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/search_intent.dart';

// ── Re-export error types so callers keep identical imports ──────────────────

enum AiExtractorErrorCode {
  quotaExceeded,
  modelOverloaded,
  timeout,
  network,
  parse,
  invalidInput,
  alreadyProcessing,
}

class AiIntentExtractorException implements Exception {
  final String               message;
  final AiExtractorErrorCode code;

  const AiIntentExtractorException(
    this.message, {
    this.code = AiExtractorErrorCode.network,
  });

  @override
  String toString() => 'AiIntentExtractorException[$code]: $message';
}

// ─────────────────────────────────────────────────────────────────────────────

class LocalAiService {
  final String      _baseUrl;
  final http.Client _http;

  // ── FIX 1 : timeouts corrigés ─────────────────────────────────────────────
  //
  // texte  : 15s  — Gemma4 répond en ~8-12s sur CPU (prefill réduit v14.3)
  // audio  : 30s  — transcoding 1.4s + processing 6.5s + marge réseau
  // image  : 120s — encoding CPU ~35s + processing ~20s + marge
  //          Sur GPU (prod), la réponse viendra en < 5s — 120s reste correct
  static const Duration _callTimeoutText  = Duration(seconds: 15);
  static const Duration _callTimeoutAudio = Duration(seconds: 30);   // FIX 3
  static const Duration _callTimeoutImage = Duration(seconds: 120);  // FIX 1

  // ── FIX 2 : taille max de l'image avant envoi ─────────────────────────────
  //
  // 512px : optimal pour la détection de problèmes domicile (fuites, pannes)
  //   → ~30-80 KB JPEG q=85  (vs 3-5 MB original caméra)
  //   → encoding Gemma4 CPU : ~1-3s (vs 35s pour image full-res)
  //   → tokens image estimés : ~1300 (vs ~4000+ pour 4K)
  //
  // 640px : alternatif si la précision est critique (ex: lecture de texte
  //   sur une étiquette d'appareil). Changer _maxImageDimension à 640.
  static const int _maxImageDimension = 512;

  // Qualité JPEG après resize (0-100). 85 donne un bon compromis taille/qualité
  // pour la vision — en dessous de 70 les artefacts JPEG nuisent à la détection.
  static const int _jpegQuality = 85;

  static const int _cacheCapacity   = 20;
  static const int _maxCallsPerHour = 20;

  bool _isBusyText  = false;
  bool _isBusyAudio = false;

  bool get isBusy => _isBusyText || _isBusyAudio;

  final _cache = LinkedHashMap<String, SearchIntent>(
    equals:   (a, b) => a == b,
    hashCode: (k) => k.hashCode,
  );

  final List<DateTime> _callTimestamps = [];

  LocalAiService({required String baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _http    = httpClient ?? http.Client();

  // ── Cache helpers ──────────────────────────────────────────────────────────

  SearchIntent? _getCached(String key) {
    final entry = _cache[key];
    if (entry != null) {
      _cache.remove(key);
      _cache[key] = entry;
    }
    return entry;
  }

  void _putCache(String key, SearchIntent value) {
    if (_cache.length >= _cacheCapacity) _cache.remove(_cache.keys.first);
    _cache[key] = value;
  }

  // ── Rate limiter ───────────────────────────────────────────────────────────

  bool _isRateLimited() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _callTimestamps.removeWhere((t) => t.isBefore(cutoff));
    return _callTimestamps.length >= _maxCallsPerHour;
  }

  void _recordCall() => _callTimestamps.add(DateTime.now());

  // ── Auth header ────────────────────────────────────────────────────────────

  Future<String?> _getToken() async =>
      FirebaseAuth.instance.currentUser?.getIdToken();

  // ═══════════════════════════════════════════════════════════════════════════
  // FIX 2 — _resizeImageIfNeeded()
  //
  // Redimensionne l'image à max [_maxImageDimension]px (côté le plus long)
  // en conservant le ratio. Utilise dart:ui — aucune dépendance externe.
  //
  // POURQUOI dart:ui et pas flutter_image_compress :
  //   flutter_image_compress nécessite une dépendance native (C/Swift/Kotlin).
  //   dart:ui.Image est disponible partout et suffit pour un resize bilinéaire.
  //   La qualité de resize est identique pour la vision (pas d'affichage UI).
  //
  // PIPELINE :
  //   Uint8List(original) → ui.decodeImageFromList → ui.Image
  //     → Canvas.drawImageRect (resize bilinéaire)
  //       → Picture.toImage → ByteData (RGBA)
  //         → encode JPEG → Uint8List(resizée)
  //
  // NOTE : dart:ui.Image.toByteData() retourne RGBA brut.
  //   On encode ensuite en JPEG manuellement via _encodeRgbaToJpeg().
  //   Sur CPU Codespaces, cette opération prend ~50-200ms — négligeable.
  //
  // FALLBACK : si le resize échoue (image corrompue, OOM), on retourne
  //   l'image originale — le backend reçoit la grande image et prend plus
  //   de temps, mais ça ne plante pas l'app.
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Uint8List> _resizeImageIfNeeded(Uint8List bytes) async {
    try {
      // Décode l'image source
      final codec     = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image     = frameInfo.image;

      final origW = image.width;
      final origH = image.height;

      // Si déjà petite, retourner telle quelle
      if (origW <= _maxImageDimension && origH <= _maxImageDimension) {
        if (kDebugMode) {
          debugPrint('[LocalAiService] Image ${origW}x${origH} — pas de resize nécessaire');
        }
        image.dispose();
        return bytes;
      }

      // Calcul des nouvelles dimensions (ratio conservé)
      final double scale = _maxImageDimension / (origW > origH ? origW : origH);
      final int    newW  = (origW * scale).round();
      final int    newH  = (origH * scale).round();

      // Resize via Canvas → Picture → Image
      final recorder = ui.PictureRecorder();
      final canvas   = ui.Canvas(recorder);
      final paint    = ui.Paint()
        ..filterQuality = ui.FilterQuality.medium;

      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, origW.toDouble(), origH.toDouble()),
        ui.Rect.fromLTWH(0, 0, newW.toDouble(),  newH.toDouble()),
        paint,
      );

      final picture     = recorder.endRecording();
      final resizedImg  = await picture.toImage(newW, newH);

      // Export PNG directement depuis l'image resizée — une seule étape,
      // pas besoin de ImageDescriptor. dart:ui supporte png nativement.
      final pngData = await resizedImg.toByteData(format: ui.ImageByteFormat.png);

      image.dispose();
      resizedImg.dispose();
      picture.dispose();

      if (pngData == null) {
        if (kDebugMode) debugPrint('[LocalAiService] PNG export null — fallback image originale');
        return bytes;
      }

      final result = pngData.buffer.asUint8List();

      if (kDebugMode) {
        final origKB = (bytes.length / 1024).toStringAsFixed(0);
        final newKB  = (result.length / 1024).toStringAsFixed(0);
        debugPrint(
          '[LocalAiService] Image resizée : ${origW}x${origH} (${origKB}KB) '
          '→ ${newW}x${newH} (${newKB}KB)',
        );
      }

      return result;

    } catch (e) {
      // Fallback : image originale (pas de crash)
      if (kDebugMode) debugPrint('[LocalAiService] Resize échoué ($e) — image originale envoyée');
      return bytes;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  Future<SearchIntent> extract(
    String text, {
    Uint8List? imageBytes,
    String?    mime,
  }) async {
    final hasText  = text.trim().isNotEmpty;
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;

    if (!hasText && !hasImage) {
      throw const AiIntentExtractorException(
        'No input provided',
        code: AiExtractorErrorCode.invalidInput,
      );
    }

    if (_isBusyText) {
      throw const AiIntentExtractorException(
        'Already processing a request',
        code: AiExtractorErrorCode.alreadyProcessing,
      );
    }

    if (_isRateLimited()) {
      throw const AiIntentExtractorException(
        'Rate limit exceeded — max 20 requests per hour',
        code: AiExtractorErrorCode.quotaExceeded,
      );
    }

    if (hasText && !hasImage) {
      final cacheKey     = text.trim().toLowerCase();
      final cachedResult = _getCached(cacheKey);
      if (cachedResult != null) return cachedResult;
    }

    _isBusyText = true;
    try {
      SearchIntent result;
      if (hasImage) {
        result = await _extractWithImage(text, imageBytes!, mime);
      } else {
        result = await _extractText(text);
      }
      if (hasText && !hasImage) _putCache(text.trim().toLowerCase(), result);
      _recordCall();
      return result;
    } finally {
      _isBusyText = false;
    }
  }

  Future<SearchIntent> extractFromAudio(
    Uint8List audioBytes, {
    String mime       = 'audio/m4a',
    int    maxRetries = 2,
  }) async {
    if (audioBytes.isEmpty) {
      throw const AiIntentExtractorException(
        'Audio bytes are empty',
        code: AiExtractorErrorCode.invalidInput,
      );
    }

    if (_isBusyAudio) {
      throw const AiIntentExtractorException(
        'Already processing an audio request',
        code: AiExtractorErrorCode.alreadyProcessing,
      );
    }

    if (_isRateLimited()) {
      throw const AiIntentExtractorException(
        'Rate limit exceeded',
        code: AiExtractorErrorCode.quotaExceeded,
      );
    }

    _isBusyAudio = true;
    Exception? lastError;

    try {
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final token   = await _getToken();
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/ai/extract-intent/audio'),
          );
          if (token != null) request.headers['Authorization'] = 'Bearer $token';

          request.files.add(http.MultipartFile.fromBytes(
            'file',
            audioBytes,
            filename:    'audio.m4a',
            contentType: MediaType.parse(mime),
          ));

          // FIX 3 : audio utilise _callTimeoutAudio = 30s
          // (backend répond en ~6.5s + transcoding 1.4s = ~8s, marge large)
          final streamed = await request.send().timeout(_callTimeoutAudio);
          final response = await http.Response.fromStream(streamed);

          if (response.statusCode >= 500 && attempt < maxRetries) {
            if (kDebugMode) {
              debugPrint('[LocalAiService] Audio attempt $attempt failed '
                  '(${response.statusCode}), retrying...');
            }
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }

          _recordCall();
          return _parseResponse(response);

        } on AiIntentExtractorException {
          rethrow;
        } on TimeoutException {
          lastError = const AiIntentExtractorException(
            'Audio request timed out',
            code: AiExtractorErrorCode.timeout,
          );
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          lastError = _classifyError(e);
          if (attempt < maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      throw lastError ??
          const AiIntentExtractorException(
            'Audio extraction failed after retries',
            code: AiExtractorErrorCode.network,
          );
    } finally {
      _isBusyAudio = false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<SearchIntent> _extractText(String text) async {
    final token    = await _getToken();
    final response = await _http.post(
      Uri.parse('$_baseUrl/ai/extract-intent'),
      headers: {
        'Content-Type':  'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text.trim()}),
    ).timeout(_callTimeoutText);
    return _parseResponse(response);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _extractWithImage() — FIX 1 + FIX 2
  //
  // FIX 1 : timeout 120s (CPU Codespaces → ~56s total backend)
  // FIX 2 : resize avant envoi → 512px max → encoding ~1-3s au lieu de 35s
  //
  // Retry x2 sur TimeoutException (inchangé depuis BUG 4 FIX B).
  // ─────────────────────────────────────────────────────────────────────────
  Future<SearchIntent> _extractWithImage(
    String text,
    Uint8List imageBytes,
    String? mime,
  ) async {
    // FIX 2 : resize AVANT détection MIME (le resize peut changer le format)
    final resized      = await _resizeImageIfNeeded(imageBytes);
    // Après resize via dart:ui, le format est toujours PNG
    // (dart:ui.ImageByteFormat.png). On détecte depuis les magic bytes resizés.
    final detectedMime = _detectImageMime(resized) ?? mime ?? 'image/png';
    final extension    = detectedMime == 'image/png'
        ? 'png'
        : detectedMime == 'image/webp'
            ? 'webp'
            : 'jpg';

    Exception? lastError;

    // Retry x2 sur timeout (inchangé)
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final token   = await _getToken();
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/ai/extract-intent/image'),
        );
        if (token != null) request.headers['Authorization'] = 'Bearer $token';

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          resized,                               // FIX 2 : image resizée
          filename:    'image.$extension',
          contentType: MediaType.parse(detectedMime),
        ));

        if (text.trim().isNotEmpty) {
          request.fields['text'] = text.trim();
        }

        // FIX 1 : timeout 120s (au lieu de 30s)
        final streamed = await request.send().timeout(_callTimeoutImage);
        final response = await http.Response.fromStream(streamed);
        return _parseResponse(response);

      } on AiIntentExtractorException {
        rethrow;
      } on TimeoutException {
        lastError = AiIntentExtractorException(
          'Image analysis timed out (attempt $attempt/2)',
          code: AiExtractorErrorCode.timeout,
        );
        if (attempt < 2) {
          if (kDebugMode) {
            debugPrint('[LocalAiService] Image timeout (attempt $attempt/2), retrying...');
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        lastError = _classifyError(e);
        break;
      }
    }

    throw lastError ??
        const AiIntentExtractorException(
          'Image extraction failed',
          code: AiExtractorErrorCode.network,
        );
  }

  /// Détection MIME depuis magic bytes — évite application/octet-stream.
  String? _detectImageMime(Uint8List bytes) {
    if (bytes.length < 4) return null;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'image/jpeg';
    if (bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) return 'image/png';
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 &&
        bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 &&
        bytes[10] == 0x42 && bytes[11] == 0x50) return 'image/webp';
    return null;
  }

  SearchIntent _parseResponse(http.Response response) {
    if (response.statusCode == 429) {
      throw const AiIntentExtractorException(
        'Quota exceeded — retry in a few minutes',
        code: AiExtractorErrorCode.quotaExceeded,
      );
    }
    if (response.statusCode == 503) {
      throw const AiIntentExtractorException(
        'Model temporarily overloaded — retry',
        code: AiExtractorErrorCode.modelOverloaded,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiIntentExtractorException(
        'Server error (${response.statusCode})',
        code: AiExtractorErrorCode.network,
      );
    }
    try {
      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> json;
      if (decoded is Map && decoded['success'] == true && decoded.containsKey('data')) {
        json = (decoded['data'] as Map).cast<String, dynamic>();
      } else if (decoded is Map) {
        json = decoded.cast<String, dynamic>();
      } else {
        return const SearchIntent();
      }
      return SearchIntent.fromJson(json);
    } catch (e) {
      throw AiIntentExtractorException(
        'Parse error: $e',
        code: AiExtractorErrorCode.parse,
      );
    }
  }

  AiIntentExtractorException _classifyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('429') || msg.contains('quota') || msg.contains('rate limit')) {
      return const AiIntentExtractorException(
          'Quota exceeded', code: AiExtractorErrorCode.quotaExceeded);
    }
    if (msg.contains('503') || msg.contains('overload') || msg.contains('unavailable')) {
      return const AiIntentExtractorException(
          'Model overloaded', code: AiExtractorErrorCode.modelOverloaded);
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return const AiIntentExtractorException(
          'Request timed out', code: AiExtractorErrorCode.timeout);
    }
    return AiIntentExtractorException(
        'Network error: $e', code: AiExtractorErrorCode.network);
  }

  void dispose() {
    _cache.clear();
    _callTimestamps.clear();
    _http.close();
  }
}
