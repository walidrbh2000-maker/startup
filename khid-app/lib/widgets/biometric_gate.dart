// lib/widgets/biometric_gate.dart
//
// Wraps the whole app (via MaterialApp.router's builder). When the biometric
// lock is enabled it covers the UI with a lock screen on cold start and every
// time the app returns from the background, clearing only after a successful
// device auth. When disabled it is a transparent pass-through.

import 'package:flutter/material.dart';

import '../services/biometric_lock_service.dart';
import '../utils/localization.dart';

class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  final _service = BiometricLockService();
  bool _enabled = false;
  bool _locked  = false;
  bool _authing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.isEnabled().then((enabled) {
      if (!mounted) return;
      setState(() { _enabled = enabled; _locked = enabled; });
      if (enabled) _prompt();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-read the pref each background→foreground cycle so toggling it in
    // Settings takes effect without a restart.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _service.isEnabled().then((enabled) {
        _enabled = enabled;
        if (enabled && mounted) setState(() => _locked = true);
      });
    } else if (state == AppLifecycleState.resumed) {
      if (_enabled && _locked) _prompt();
    }
  }

  Future<void> _prompt() async {
    if (_authing) return;
    _authing = true;
    final ok = await _service.authenticate(context.tr('auth.biometric_reason'));
    _authing = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _LockScreen(authing: _authing, onUnlock: _prompt),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  final bool         authing;
  final VoidCallback onUnlock;
  const _LockScreen({required this.authing, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('Khidmeti', style: theme.textTheme.titleLarge),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: authing ? null : onUnlock,
              icon:  const Icon(Icons.fingerprint),
              label: Text(context.tr('auth.biometric_unlock')),
            ),
          ],
        ),
      ),
    );
  }
}
