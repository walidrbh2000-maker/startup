// lib/screens/auth/pin_verify_screen.dart
//
// Account-PIN gate (anti SIM-recycling): the backend answered PIN_REQUIRED —
// this account has an optional security PIN and this device is not yet
// trusted. Every API call is rejected until POST /auth/verify-pin succeeds,
// so the router pins the user here (see pinGateProvider).
//
// Forgot PIN → starts the 7-day WhatsApp-style cooling period (no SMS/email
// recovery: SMS is the channel this feature distrusts).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/otp_input_row.dart';

class PinVerifyScreen extends ConsumerStatefulWidget {
  const PinVerifyScreen({super.key});

  @override
  ConsumerState<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<PinVerifyScreen> {
  final _pinKey = GlobalKey<OtpInputRowState>();

  bool    _busy = false;
  String? _errorKey;

  Future<void> _verify(String pin) async {
    if (_busy || pin.length != AppConstants.otpLength) return;
    HapticFeedback.mediumImpact();
    setState(() { _busy = true; _errorKey = null; });

    try {
      final reason = await ref.read(apiServiceProvider).verifyAccountPin(pin);
      if (!mounted) return;

      if (reason == null) {
        // Device now trusted. Resolve the role HERE before dropping the gate:
        // going via /splash would race the router with cachedRole==unknown
        // (→ spurious role-selection). Sockets were server-disconnected while
        // gated (no auto-reconnect after "io server disconnect") — force a
        // reconnect with the now-trusted deviceId.
        await ref.read(realtimeServiceProvider).reconnectWithFreshAuth();
        // safeDefault:false — a swallowed transient error here would send an
        // EXISTING user to role-selection and mis-cache their role. Throwing
        // lands in the outer catch: user stays here and retries (verify is
        // idempotent once the device is trusted).
        final check = await ref.read(apiServiceProvider).checkAuthUser(
              FirebaseAuth.instance.currentUser?.uid ?? '',
              safeDefault: false,
            );
        if (!mounted) return;
        setCachedUserRole(
          ref.read(cachedUserRoleProvider.notifier),
          check.role == 'worker' ? UserRole.worker : UserRole.client,
          force: true,
        );
        ref.read(pinGateProvider.notifier).state = false;
        context.go(check.isNewUser ? AppRoutes.roleSelection : AppRoutes.home);
        return;
      }

      _pinKey.currentState?.clear();
      setState(() {
        _busy     = false;
        _errorKey = reason == 'locked' ? 'pin.locked' : 'pin.wrong_pin';
      });
    } catch (_) {
      if (!mounted) return;
      _pinKey.currentState?.clear();
      setState(() { _busy = false; _errorKey = 'errors.network'; });
    }
  }

  Future<void> _forgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   Text(context.tr('pin.forgot')),
        content: Text(context.tr('pin.reset_info')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child:     Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child:     Text(context.tr('common.confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(apiServiceProvider).requestPinReset();
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, context.tr('pin.reset_started'));
    } catch (_) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, context.tr('errors.network'));
    }
  }

  Future<void> _useAnotherAccount() async {
    // Sign out drops the gate; the router routes to phone auth.
    ref.read(pinGateProvider.notifier).state = false;
    await ref.read(settingsProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            AuthBackground(isDark: isDark),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left:   AppConstants.paddingLg,
                  right:  AppConstants.paddingLg,
                  top:    AppConstants.paddingXl,
                  bottom: MediaQuery.viewInsetsOf(context).bottom +
                      AppConstants.paddingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.spacingXl),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingXl),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                        border: Border.all(
                          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                          width: AppConstants.borderWidthDefault,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size:  AppConstants.iconSizeXl,
                            color: isDark ? AppTheme.darkAccentText : AppTheme.lightAccent,
                          ),
                          const SizedBox(height: AppConstants.spacingMd),
                          Text(
                            context.tr('pin.verify_title'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                ),
                          ),
                          const SizedBox(height: AppConstants.spacingXs),
                          Text(
                            context.tr('pin.verify_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeSm,
                              color: isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingLg),
                          OtpInputRow(
                            key:         _pinKey,
                            hasError:    _errorKey != null,
                            onCompleted: _verify,
                          ),
                          if (_errorKey != null) ...[
                            const SizedBox(height: AppConstants.spacingSm),
                            Text(
                              context.tr(_errorKey!),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppConstants.fontSizeSm,
                                color: isDark ? AppTheme.darkError : AppTheme.lightError,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppConstants.spacingLg),
                          AuthSubmitButton(
                            isLoading: _busy,
                            isDark:    isDark,
                            labelKey:  'pin.verify',
                            onPressed: _busy
                                ? null
                                : () => _verify(_pinKey.currentState?.currentCode ?? ''),
                          ),
                          const SizedBox(height: AppConstants.spacingMd),
                          TextButton(
                            onPressed: _busy ? null : _forgotPin,
                            child: Text(context.tr('pin.forgot')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    TextButton(
                      onPressed: _busy ? null : _useAnotherAccount,
                      child: Text(context.tr('pin.use_another_account')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
