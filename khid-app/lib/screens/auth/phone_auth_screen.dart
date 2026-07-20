// lib/screens/auth/phone_auth_screen.dart
//
// Firebase Phone Authentication — two animated cards:
//   Phone entry : country code picker + 9-digit input
//   OTP entry   : 6-box grid, resend timer, auto-submit
// (Cooldown ticks live in the auth controller, not here.)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/auth_state.dart';
import '../../providers/auth_controller.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/user_role_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/wordmark.dart';
import '../auth/widgets/auth_background.dart';
import '../auth/widgets/auth_submit_button.dart';
import 'widgets/auth_locale_bar.dart';
import 'widgets/country_code_picker.dart';
import 'widgets/otp_input_row.dart';

// ─────────────────────────────────────────────────────────────────────────────

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen>
    with SingleTickerProviderStateMixin {

  // ── Phone state ─────────────────────────────────────────────────────────────
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = kDefaultCountry;
  bool _phoneValid = false;

  /// Length gate follows the selected country (TN/MR are 8 digits, DE/EG/US
  /// are 10+) — re-run on both text edits and country switches.
  void _revalidatePhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final valid = digits.length >= _selectedCountry.minDigits &&
        digits.length <= _selectedCountry.maxDigits;
    if (valid != _phoneValid) setState(() => _phoneValid = valid);
  }

  // ── OTP state ───────────────────────────────────────────────────────────────
  final _otpKey = GlobalKey<OtpInputRowState>();
  bool _otpSubmitting = false;

  // ── Animations ──────────────────────────────────────────────────────────────
  late final AnimationController _cardController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(_revalidatePhone);

    _cardController = AnimationController(
      vsync: this,
      duration: AppConstants.authCardEntranceDuration,
    )..forward();

    _cardFade =
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // ── Navigation after successful authentication ─────────────────────────────

  Future<void> _handleExistingUserLogin() async {
    try {
      final role = await ref.read(currentUserRoleProvider.future);
      if (!mounted) return;
      setCachedUserRole(
        ref.read(cachedUserRoleProvider.notifier),
        role,
        force: true,
      );
    } catch (_) {
      if (!mounted) return;
      setCachedUserRole(
        ref.read(cachedUserRoleProvider.notifier),
        UserRole.client,
        force: true,
      );
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  // ── Phone submission ────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_phoneValid) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final e164 = '${_selectedCountry.dialCode}$raw';

    await ref.read(authControllerProvider.notifier).sendOtp(e164);
  }

  // ── Continue as guest ───────────────────────────────────────────────────────

  Future<void> _continueAsGuest() async {
    HapticFeedback.selectionClick();
    try {
      // Router redirect routes the anonymous session straight to home.
      await ref.read(authServiceProvider).signInAnonymously();
    } catch (_) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, context.tr('errors.generic'));
    }
  }

  // ── OTP submission ──────────────────────────────────────────────────────────

  Future<void> _verifyOtp(String code) async {
    if (code.length != AppConstants.otpLength || _otpSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _otpSubmitting = true);
    await ref.read(authControllerProvider.notifier).verifyOtp(code);
    if (mounted) setState(() => _otpSubmitting = false);
  }

  Future<void> _resendOtp() async {
    _otpKey.currentState?.clear();
    await ref.read(authControllerProvider.notifier).resendOtp();
  }

  // ── Back to phone ───────────────────────────────────────────────────────────

  void _backToPhone() {
    ref.invalidate(authControllerProvider);
    _phoneController.clear();
    _otpKey.currentState?.clear();
    _cardController.reset();
    _cardController.forward();
  }

  // ── Country picker ──────────────────────────────────────────────────────────

  Future<void> _pickCountry() async {
    FocusScope.of(context).unfocus();
    final result = await showCountryCodePicker(context);
    if (result != null && mounted) {
      setState(() => _selectedCountry = result);
      _revalidatePhone();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (!mounted) return;
      if (next.status != AuthStatus.success) return;

      // Account-PIN gate: OTP passed but this device must present the PIN
      // before anything else (SIM-recycling defense) — role resolution would
      // only get PIN_REQUIRED errors anyway. Always assign (not just set on
      // true): a stale gate from a previous session must never trap a fresh
      // sign-in on an unprotected account.
      ref.read(pinGateProvider.notifier).state = next.pinRequired;
      if (next.pinRequired) {
        context.go(AppRoutes.pinVerify);
        return;
      }

      // Document-approval gate: account exists but its documents await (or
      // were denied) admin review — park on the pending screen. Same "always
      // assign" rule as the PIN gate to clear stale state.
      ref.read(approvalGateProvider.notifier).state = next.approvalRequired;
      if (next.approvalRequired) {
        context.go(AppRoutes.pendingApproval);
        return;
      }

      if (next.isNewUser) {
        context.go(AppRoutes.roleSelection);
      } else {
        _handleExistingUserLogin();
      }
    });

    final isOtpPhase = authState.status == AuthStatus.otpSent ||
        authState.status == AuthStatus.verifying ||
        authState.status == AuthStatus.success ||
        // A failed verify keeps verificationId — stay on the OTP card and let
        // its error banner show, instead of bouncing back to phone entry.
        (authState.hasError && authState.verificationId != null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // System back during the OTP phase returns to the phone-entry card
      // (same as the in-card "change number" link) instead of exiting the
      // app. On the phone card the stack is empty — back exits, as expected
      // for the app's entry screen.
      child: PopScope(
        canPop: !isOtpPhase,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _backToPhone();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              AuthBackground(isDark: isDark),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppConstants.paddingLg,
                    right: AppConstants.paddingLg,
                    top: AppConstants.paddingXl,
                    bottom: MediaQuery.viewInsetsOf(context).bottom +
                        AppConstants.paddingXl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header left, locale/theme controls top-right — the
                      // international-app convention (locale lives on the auth
                      // entry screen only).
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _AuthHeader(isDark: isDark)),
                          const AuthLocaleBar(),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingXl),
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: AnimatedSwitcher(
                            duration: AppConstants.animDurationShort,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: child,
                            ),
                            child: isOtpPhase
                                ? _OtpCard(
                                    key: const ValueKey('otp'),
                                    authState: authState,
                                    isDark: isDark,
                                    otpKey: _otpKey,
                                    onCompleted: _verifyOtp,
                                    onResend: _resendOtp,
                                    onBack: _backToPhone,
                                  )
                                : _PhoneCard(
                                    key: const ValueKey('phone'),
                                    authState: authState,
                                    isDark: isDark,
                                    controller: _phoneController,
                                    country: _selectedCountry,
                                    phoneValid: _phoneValid,
                                    onPickCountry: _pickCountry,
                                    onSubmit: _sendOtp,
                                    onGuest: _continueAsGuest,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth header
// ─────────────────────────────────────────────────────────────────────────────

// "Point Final" identity carried from splash/onboarding: accent rule +
// wordmark — no icon orb.
class _AuthHeader extends StatelessWidget {
  final bool isDark;
  const _AuthHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AccentRule(),
        const SizedBox(height: AppConstants.spacingMd),
        Semantics(
          header: true,
          label: context.tr('common.app_name'),
          child: AppWordmark(
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone entry card
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneCard extends StatelessWidget {
  final AuthState authState;
  final bool isDark;
  final TextEditingController controller;
  final CountryCode country;
  final bool phoneValid;
  final VoidCallback onPickCountry;
  final VoidCallback onSubmit;
  final VoidCallback onGuest;

  const _PhoneCard({
    super.key,
    required this.authState,
    required this.isDark,
    required this.controller,
    required this.country,
    required this.phoneValid,
    required this.onPickCountry,
    required this.onSubmit,
    required this.onGuest,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('phone_auth.title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            context.tr('phone_auth.subtitle'),
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          _PhoneInputRow(
            isDark: isDark,
            controller: controller,
            country: country,
            onPickCountry: onPickCountry,
            onSubmit: onSubmit,
          ),
          if (authState.hasError && authState.errorKey != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            _ErrorBanner(messageKey: authState.errorKey!, isDark: isDark),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          AuthSubmitButton(
            isLoading: authState.status == AuthStatus.sendingOtp,
            isDark: isDark,
            onPressed:
                phoneValid && authState.status != AuthStatus.sendingOtp
                    ? onSubmit
                    : null,
            labelKey: 'phone_auth.send_code',
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            context.tr('phone_auth.sms_disclaimer'),
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(
            onPressed:
                authState.status == AuthStatus.sendingOtp ? null : onGuest,
            child: Text(context.tr('auth.continue_as_guest')),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone input row
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneInputRow extends StatefulWidget {
  final bool isDark;
  final TextEditingController controller;
  final CountryCode country;
  final VoidCallback onPickCountry;
  final VoidCallback onSubmit;

  const _PhoneInputRow({
    required this.isDark,
    required this.controller,
    required this.country,
    required this.onPickCountry,
    required this.onSubmit,
  });

  @override
  State<_PhoneInputRow> createState() => _PhoneInputRowState();
}

class _PhoneInputRowState extends State<_PhoneInputRow> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    // Border color animates; width stays constant so focus never shifts layout.
    final borderColor = _isFocused
        ? accent
        : (widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder);

    // Subtle accent wash when focused — reinforces "active" state beyond
    // just the border color change.
    final fillColor = _isFocused
        ? (widget.isDark
            ? AppTheme.darkAccent.withValues(alpha: 0.06)
            : AppTheme.lightAccent.withValues(alpha: 0.04))
        : (widget.isDark
            ? AppTheme.darkSurfaceVariant
            : AppTheme.lightSurfaceVariant);

    return AnimatedContainer(
      duration: AppConstants.animDurationMicro,
      height: AppConstants.inputFieldHeight,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        border: Border.all(
          color: borderColor,
          width: AppConstants.borderWidthDefault,
        ),
      ),
      child: Row(
        children: [
          // ── Country code button ──────────────────────────────────────────
          Semantics(
            button: true,
            label:
                '${context.tr('phone_auth.country_code')}: ${widget.country.name} ${widget.country.dialCode}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPickCountry,
                borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                child: SizedBox(
                  height: AppConstants.inputFieldHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMd,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.country.flag,
                          style: const TextStyle(
                              fontSize: AppConstants.iconSizeSm),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.country.dialCode,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeMd,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppTheme.darkText
                                : AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingXxs),
                        Icon(
                          AppIcons.arrowDown,
                          size: AppConstants.iconSizeXs,
                          color: widget.isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Slim floating divider — avoids a harsh double line against the
          // outer stroke.
          Container(
            width: 1,
            height: 22,
            color: (widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                .withValues(alpha: 0.7),
          ),

          // ── Phone number input ───────────────────────────────────────────
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              // Cap follows the selected country's national number length.
              maxLength: widget.country.maxDigits,
              onSubmitted: (_) => widget.onSubmit(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                fontSize: AppConstants.fontSizeLg,
                fontWeight: FontWeight.w400,
                color:
                    widget.isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '6XXXXXXXX',
                hintStyle: TextStyle(
                  color: widget.isDark
                      ? AppTheme.darkHintText
                      : AppTheme.lightHintText,
                  fontSize: AppConstants.fontSizeLg,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMd,
                  vertical: AppConstants.paddingMd,
                ),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP card
// ─────────────────────────────────────────────────────────────────────────────

class _OtpCard extends StatelessWidget {
  final AuthState authState;
  final bool isDark;
  final GlobalKey<OtpInputRowState> otpKey;
  final ValueChanged<String> onCompleted;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _OtpCard({
    super.key,
    required this.authState,
    required this.isDark,
    required this.otpKey,
    required this.onCompleted,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isVerifyingOrDone = authState.status == AuthStatus.verifying ||
        authState.status == AuthStatus.success;
    final cooldown = authState.resendCooldown;
    final phone = authState.phone;
    final masked = phone.length >= 4
        ? '${phone.substring(0, phone.length - 4)}****'
        : phone;

    return _AuthCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isVerifyingOrDone)
            Semantics(
              button: true,
              label: context.tr('phone_auth.change_number'),
              child: GestureDetector(
                onTap: onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.back,
                      size: AppConstants.iconSizeSm,
                      color: isDark
                          ? AppTheme.darkAccentText
                          : AppTheme.lightAccent,
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Text(
                      context.tr('phone_auth.change_number'),
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkAccentText
                            : AppTheme.lightAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!isVerifyingOrDone)
            const SizedBox(height: AppConstants.spacingMd),

          Text(
            context.tr('phone_auth.otp_title'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
          ),

          const SizedBox(height: AppConstants.spacingXs),

          Text(
            '${context.tr("phone_auth.otp_sent_to")} $masked',
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),

          OtpInputRow(
            key: otpKey,
            hasError: authState.hasError,
            onCompleted: onCompleted,
            onChanged: () {},
          ),

          if (authState.hasError && authState.errorKey != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            _ErrorBanner(
              messageKey: authState.errorKey!,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: AppConstants.spacingLg),

          AuthSubmitButton(
            isLoading: isVerifyingOrDone,
            isDark: isDark,
            onPressed: isVerifyingOrDone
                ? null
                : () {
                    final code = otpKey.currentState?.currentCode ?? '';
                    if (code.length == AppConstants.otpLength) {
                      onCompleted(code);
                    }
                  },
            labelKey: 'phone_auth.verify',
          ),

          const SizedBox(height: AppConstants.spacingMd),

          if (!isVerifyingOrDone)
            _ResendTimer(
              cooldown: cooldown,
              isDark: isDark,
              onResend: cooldown == 0 ? onResend : null,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resend timer
// ─────────────────────────────────────────────────────────────────────────────

class _ResendTimer extends StatelessWidget {
  final int cooldown;
  final bool isDark;
  final VoidCallback? onResend;

  const _ResendTimer({
    required this.cooldown,
    required this.isDark,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccentText : AppTheme.lightAccent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr('phone_auth.resend_prefix'),
          style: TextStyle(
            fontSize: AppConstants.fontSizeSm,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
        ),
        const SizedBox(width: AppConstants.spacingXs),
        if (cooldown > 0)
          Text(
            '${cooldown}s',
            style: TextStyle(
              fontSize: AppConstants.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          )
        else
          Semantics(
            button: true,
            label: context.tr('phone_auth.resend'),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onResend?.call();
              },
              child: Text(
                context.tr('phone_auth.resend'),
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSm,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String messageKey;
  final bool isDark;

  const _ErrorBanner({required this.messageKey, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMd),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkErrorSubtle : AppTheme.lightErrorSubtle,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: (isDark ? AppTheme.darkError : AppTheme.lightError)
              .withValues(alpha: 0.30),
          width: AppConstants.borderWidthDefault,
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.error,
            size: AppConstants.iconSizeXs,
            color: isDark ? AppTheme.darkError : AppTheme.lightError,
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              context.tr(messageKey),
              style: TextStyle(
                fontSize: AppConstants.fontSizeSm,
                color: isDark ? AppTheme.darkError : AppTheme.lightError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth card container
// ─────────────────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _AuthCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingXl),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: AppConstants.borderWidthDefault,
        ),
      ),
      child: child,
    );
  }
}
