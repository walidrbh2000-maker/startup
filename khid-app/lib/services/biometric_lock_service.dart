// lib/services/biometric_lock_service.dart
//
// App-lock via device biometric (fingerprint / face), with device PIN fallback.
// Sits on top of Firebase auth: it does not replace login, it gates re-opening
// the app. The on/off preference lives in SharedPreferences.

import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricLockService {
  static const _prefKey = 'biometric_lock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_prefKey) ?? false;

  Future<void> setEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_prefKey, value);

  /// True when the device can actually do biometric/PIN auth. Guard the settings
  /// toggle with this so we never enable a lock the user can't clear.
  Future<bool> canUse() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS auth sheet. Returns true only on success. `biometricOnly`
  /// is false so the device PIN/pattern is a fallback — losing a fingerprint
  /// must never lock the user out permanently.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth:    true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
