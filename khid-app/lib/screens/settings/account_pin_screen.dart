// lib/screens/settings/account_pin_screen.dart
//
// Account-PIN management (optional, recommended — anti SIM-recycling).
// Three flows over one 6-digit input, driven by a step machine:
//   set:    enter new → confirm new            → POST /auth/pin
//   change: current → enter new → confirm new  → POST /auth/pin {currentPin}
//   remove: current                            → POST /auth/pin/remove
//
// The PIN protects the ACCOUNT (server-side device gate), unlike the
// biometric toggle which only locks this phone's app UI.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/app_sliver_header.dart';
import '../../widgets/back_button.dart';
import '../auth/widgets/auth_submit_button.dart';
import '../auth/widgets/otp_input_row.dart';

enum _Flow { set, change, remove }
enum _Step { current, enter, confirm }

class AccountPinScreen extends ConsumerStatefulWidget {
  const AccountPinScreen({super.key});

  @override
  ConsumerState<AccountPinScreen> createState() => _AccountPinScreenState();
}

class _AccountPinScreenState extends ConsumerState<AccountPinScreen> {
  final _pinKey = GlobalKey<OtpInputRowState>();

  bool?   _hasPin;          // null while loading
  _Flow?  _flow;            // null = menu
  _Step   _step = _Step.enter;
  String  _currentPin = '';
  String  _newPin     = '';
  bool    _busy       = false;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final uid   = ref.read(authServiceProvider).user?.uid ?? '';
      final check = await ref.read(apiServiceProvider).checkAuthUser(uid);
      if (mounted) setState(() => _hasPin = check.hasPin);
    } catch (_) {
      if (mounted) setState(() => _hasPin = false);
    }
  }

  void _start(_Flow flow) {
    setState(() {
      _flow       = flow;
      _step       = flow == _Flow.set ? _Step.enter : _Step.current;
      _currentPin = '';
      _newPin     = '';
      _errorKey   = null;
    });
  }

  void _backToMenu() {
    setState(() { _flow = null; _errorKey = null; });
  }

  Future<void> _onPin(String pin) async {
    if (_busy || pin.length != AppConstants.otpLength) return;
    HapticFeedback.selectionClick();
    _pinKey.currentState?.clear();

    switch (_step) {
      case _Step.current:
        _currentPin = pin;
        if (_flow == _Flow.remove) {
          await _submit();
        } else {
          setState(() { _step = _Step.enter; _errorKey = null; });
        }
        return;

      case _Step.enter:
        _newPin = pin;
        setState(() { _step = _Step.confirm; _errorKey = null; });
        return;

      case _Step.confirm:
        if (pin != _newPin) {
          setState(() {
            _step     = _Step.enter;
            _errorKey = 'pin.mismatch';
          });
          return;
        }
        await _submit();
    }
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _errorKey = null; });
    final api = ref.read(apiServiceProvider);

    try {
      final String? reason;
      if (_flow == _Flow.remove) {
        reason = await api.removeAccountPin(_currentPin);
      } else {
        reason = await api.setAccountPin(
          _newPin,
          currentPin: _flow == _Flow.change ? _currentPin : null,
        );
      }
      if (!mounted) return;

      if (reason == null) {
        ErrorHandler.showSuccessSnackBar(
          context,
          context.tr(_flow == _Flow.remove ? 'pin.removed' : 'pin.saved'),
        );
        appBack(context);
        return;
      }

      // Stale status: we believed no PIN existed but the backend has one
      // (checkAuthUser error-defaulted hasPin to false). Recover by switching
      // to the change flow instead of looping "wrong PIN" on the set flow.
      if (reason == 'current_pin_required') {
        setState(() {
          _busy   = false;
          _hasPin = true;
          _flow   = _Flow.change;
          _step   = _Step.current;
          _errorKey = null;
        });
        return;
      }

      setState(() {
        _busy     = false;
        _step     = _flow == _Flow.set ? _Step.enter : _Step.current;
        _errorKey = reason == 'locked' ? 'pin.locked' : 'pin.wrong_pin';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _busy = false; _errorKey = 'errors.network'; });
    }
  }

  String get _stepTitleKey => switch (_step) {
        _Step.current => 'pin.enter_current',
        _Step.enter   => 'pin.enter_new',
        _Step.confirm => 'pin.confirm_new',
      };

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // System back mirrors the header button: inside a flow it returns to
      // the PIN menu; from the menu it pops the screen.
      child: PopScope(
        canPop: _flow == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _backToMenu();
        },
        child: Scaffold(
          backgroundColor: bg,
          body: CustomScrollView(
            slivers: [
              AppSliverHeader(
                title:  context.tr('pin.title'),
                // Inside a flow, back returns to the PIN menu; from the menu
                // it leaves the screen (safe default: pop or home).
                onBack: _flow != null ? _backToMenu : null,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppConstants.paddingLg),
                sliver: SliverToBoxAdapter(
                  child: _hasPin == null
                      ? const Center(child: CircularProgressIndicator())
                      : (_flow == null ? _buildMenu(theme, isDark) : _buildPinStep(theme, isDark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(ThemeData theme, bool isDark) {
    final muted = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('pin.explainer'),
          style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.5),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        if (_hasPin == false)
          AuthSubmitButton(
            isLoading: false,
            isDark:    isDark,
            labelKey:  'pin.set',
            onPressed: () => _start(_Flow.set),
          )
        else ...[
          AuthSubmitButton(
            isLoading: false,
            isDark:    isDark,
            labelKey:  'pin.change',
            onPressed: () => _start(_Flow.change),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => _start(_Flow.remove),
            child: Text(context.tr('pin.remove')),
          ),
        ],
      ],
    );
  }

  Widget _buildPinStep(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(_stepTitleKey),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        OtpInputRow(
          key:         _pinKey,
          hasError:    _errorKey != null,
          onCompleted: _onPin,
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
        if (_busy) ...[
          const SizedBox(height: AppConstants.spacingLg),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
