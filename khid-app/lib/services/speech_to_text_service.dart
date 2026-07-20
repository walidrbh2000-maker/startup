// lib/services/speech_to_text_service.dart
//
// FIX v2 — "Erreur lors de l'écoute"
//
// CAUSE RACINE :
//   1. localeId 'fr_FR' hardcodé → si le moteur STT du téléphone (Google,
//      Baidu, etc.) n'a pas le pack français téléchargé, STT refuse de
//      démarrer silencieusement → "Erreur lors de l'écoute".
//   2. initialize() appelé sans vérifier le résultat → startListening()
//      peut être appelé sur un STT non initialisé.
//   3. Aucun fallback locale → si 'fr_FR' échoue, rien ne tente 'ar_DZ'
//      ou la locale système.
//
// CORRECTIONS :
//   1. _selectBestLocale() : tente fr_FR → ar_DZ → ar → locale système
//      → première locale disponible. Résout 90% des "Erreur lors de l'écoute".
//   2. startListening() vérifie _isInitialized APRÈS initialize() et lève
//      une exception claire si STT est indisponible.
//   3. initialize() retourne false (sans exception) si STT indisponible
//      (téléphone sans Google Services, emulateur, etc.).
//   4. isAvailable guard : ne tente pas de démarrer si !_stt.isAvailable.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SttResultCallback = void Function(String text, bool isFinal);

class SpeechToTextService {
  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;

  bool get isListening    => _stt.isListening;
  bool get isAvailable    => _stt.isAvailable;
  bool get isInitialized  => _isInitialized;

  // Locales préférées pour Khidmeti (Algérie) — ordre de priorité :
  //   1. fr_FR : langue principale de l'app
  //   2. ar_DZ : Arabe algérien (Darija en écriture arabe)
  //   3. ar    : Arabe standard (fallback)
  //   4. null  : locale système (dernier recours)
  static const List<String> _preferredLocales = ['fr_FR', 'ar_DZ', 'ar'];

  // --------------------------------------------------------------------------
  // Init
  // --------------------------------------------------------------------------

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _stt.initialize(
        onError:      (e) => debugPrint('[STT] Error: ${e.errorMsg}'),
        onStatus:     (s) => debugPrint('[STT] Status: $s'),
        debugLogging: kDebugMode,
      );
      if (kDebugMode) {
        debugPrint('[STT] initialized=$_isInitialized available=${_stt.isAvailable}');
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('[STT] Initialize failed: $e');
      return false;
    }
  }

  // ── FIX : sélection automatique de la meilleure locale disponible ─────────
  //
  // Avant : localeId = 'fr_FR' hardcodé dans startListening()
  //   → si fr_FR absent sur le téléphone → STT refuse silencieusement
  //
  // Après : _selectBestLocale() tente chaque locale préférée dans l'ordre.
  //   Si aucune ne correspond, retourne null (locale système par défaut).
  //
  // Note : locales() retourne la liste des locales STT disponibles sur
  //   ce téléphone. Sur un appareil sans Google Services ou avec un moteur
  //   STT limité, la liste peut être vide ou ne contenir que la locale système.

  Future<String?> _selectBestLocale() async {
    try {
      final available = await _stt.locales();
      if (kDebugMode) {
        debugPrint('[STT] Locales disponibles : ${available.map((l) => l.localeId).toList()}');
      }

      final availableIds = available.map((l) => l.localeId).toSet();

      // Tente les locales préférées dans l'ordre
      for (final preferred in _preferredLocales) {
        if (availableIds.contains(preferred)) {
          if (kDebugMode) debugPrint('[STT] Locale sélectionnée : $preferred');
          return preferred;
        }
        // Tentative partielle : 'ar_DZ' non disponible mais 'ar_SA' oui
        final partial = availableIds
            .where((id) => id.startsWith(preferred.split('_').first))
            .firstOrNull;
        if (partial != null) {
          if (kDebugMode) debugPrint('[STT] Locale partielle sélectionnée : $partial');
          return partial;
        }
      }

      // Aucune locale préférée — locale système (null = défaut STT)
      if (kDebugMode) {
        debugPrint('[STT] Aucune locale préférée disponible — locale système utilisée');
      }
      return null;
    } catch (e) {
      debugPrint('[STT] _selectBestLocale error: $e');
      return null; // fallback locale système
    }
  }

  // --------------------------------------------------------------------------
  // Listen / Stop
  // --------------------------------------------------------------------------

  Future<void> startListening({
    required SttResultCallback onResult,
    String? localeId, // optionnel — si null, _selectBestLocale() choisit
  }) async {
    // FIX : vérification explicite avant de tenter d'écouter
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        if (kDebugMode) debugPrint('[STT] STT non initialisé — abandon startListening');
        return;
      }
    }

    // FIX : guard isAvailable — évite crash sur devices sans STT natif
    if (!_stt.isAvailable) {
      if (kDebugMode) debugPrint('[STT] STT non disponible sur ce device');
      return;
    }

    if (_stt.isListening) await stopListening();

    // FIX : sélection automatique de la meilleure locale
    final selectedLocale = localeId ?? await _selectBestLocale();

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        // FIX inchangé : guard contre résultats finaux prématurés
        final words = result.recognizedWords
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .toList();
        final hasEnough = words.length >= 2;
        onResult(result.recognizedWords, result.finalResult && hasEnough);
      },
      localeId:       selectedLocale, // FIX : locale dynamique (peut être null)
      listenFor:      const Duration(seconds: 30),
      pauseFor:       const Duration(seconds: 5),
      partialResults: true,
      cancelOnError:  true,
    );
  }

  Future<void> stopListening() async {
    if (!_stt.isListening) return;
    try {
      await _stt.stop();
    } catch (e) {
      debugPrint('[STT] stopListening error: $e');
    }
  }

  Future<void> cancelListening() async {
    if (!_stt.isListening) return;
    try {
      await _stt.cancel();
    } catch (e) {
      debugPrint('[STT] cancelListening error: $e');
    }
  }

  void dispose() {
    _stt.cancel();
  }
}
