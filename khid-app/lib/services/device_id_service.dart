// lib/services/device_id_service.dart
//
// Stable per-install device id for the backend's account-PIN device gate
// (X-Device-Id header / WS deviceId). A random UUID persisted in
// SharedPreferences — NOT a hardware id: it only needs to be stable on this
// install and unguessable, and it resets on reinstall (a reinstall then just
// re-asks the PIN once, which is correct).
//
// Synchronous [current] getter after [init]: the HTTP layer builds headers in
// hot paths and must not await SharedPreferences on every request.

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const _prefKey = 'device_install_id';
  static String? _cached;

  /// Loaded once at startup (main.dart) before any API call.
  static Future<void> init() async {
    if (_cached != null) return;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefKey);
    if (id == null || id.isEmpty) {
      id = _generate();
      await prefs.setString(_prefKey, id);
    }
    _cached = id;
  }

  /// Null only if [init] has not run yet — callers then simply omit the
  /// header and the backend treats the request as from an unknown device.
  static String? get current => _cached;

  static String _generate() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
