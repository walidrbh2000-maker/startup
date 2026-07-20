// lib/screens/auth/pending_approval_screen.dart
//
// Document-approval gate: the account (worker with optional docs, or business
// with mandatory docs) submitted verification documents and every API call is
// rejected with APPROVAL_PENDING until an admin approves. The router pins the
// user here (see approvalGateProvider) — mirror of pin_verify_screen.dart.
//
// Polls GET /auth/check (approval-gate-exempt) every 30 s:
//   status '' (approved)  → drop the gate, resolve role, go home.
//   status 'rejected'     → show the admin's note + a resubmit button that
//                           returns to the setup screen (POST /users is exempt,
//                           so resubmission goes through).

import 'dart:async';

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
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_submit_button.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  static const Duration _pollInterval = Duration(seconds: 30);

  Timer?  _pollTimer;
  bool    _checking = false;
  bool    _leaving  = false;
  String  _status   = 'pending';   // 'pending' | 'rejected'
  String  _note     = '';

  @override
  void initState() {
    super.initState();
    // Immediate check (catches "approved while app was closed"), then poll.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    _pollTimer = Timer.periodic(_pollInterval, (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || _leaving) return;
    _checking = true;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // safeDefault:false — the newUser fallback would misread a network blip
      // as "no profile". Throw instead; we just stay parked and retry.
      final check = await ref
          .read(apiServiceProvider)
          .checkAuthUser(uid, safeDefault: false);
      if (!mounted) return;

      if (!check.needsApproval) {
        // Approved — resolve the role BEFORE dropping the gate (same pattern
        // as pin_verify: going via /splash would race cachedRole==unknown).
        setCachedUserRole(
          ref.read(cachedUserRoleProvider.notifier),
          check.role == 'worker' ? UserRole.worker : UserRole.client,
          force: true,
        );
        ref.read(approvalGateProvider.notifier).state = false;
        context.go(AppRoutes.home);
        return;
      }

      setState(() {
        _status = check.verificationStatus;
        _note   = check.verificationNote;
      });
      // Cache the role while parked: a cold start raises the gate before the
      // splash could resolve it, and _resubmit() needs it to pick the right
      // setup screen (worker vs business).
      if (check.role != null) {
        setCachedUserRole(
          ref.read(cachedUserRoleProvider.notifier),
          check.role == 'worker' ? UserRole.worker : UserRole.client,
          force: true,
        );
      }
    } catch (_) {
      // Network blip — stay parked, next poll retries.
    } finally {
      _checking = false;
    }
  }

  /// Rejected → back to the setup screen to fix + resubmit. POST /users and
  /// /media/upload/document are approval-gate-exempt, so the flow works while
  /// still gated. Role decides which setup screen.
  void _resubmit() {
    HapticFeedback.mediumImpact();
    final role = ref.read(cachedUserRoleProvider);
    // The gate stays up — the setup screens are auth-flow routes the router
    // permits below the gate redirect (see app_router).
    context.go(role == UserRole.worker
        ? AppRoutes.workerProfileSetup
        : '${AppRoutes.userProfileSetup}?type=business');
  }

  Future<void> _useAnotherAccount() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    ref.read(approvalGateProvider.notifier).state = false;
    await ref.read(settingsProvider.notifier).signOut();
    if (mounted) setState(() => _leaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final rejected = _status == 'rejected';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _useAnotherAccount();
        },
        child: Scaffold(
          body: Stack(
            children: [
              AuthBackground(isDark: isDark),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLg,
                    vertical:   AppConstants.paddingXl,
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
                              rejected
                                  ? Icons.error_outline_rounded
                                  : Icons.hourglass_top_rounded,
                              size: AppConstants.iconSizeXl,
                              color: rejected
                                  ? (isDark ? AppTheme.darkError : AppTheme.lightError)
                                  : (isDark
                                      ? AppTheme.darkAccentText
                                      : AppTheme.lightAccent),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            Text(
                              context.tr(rejected
                                  ? 'verification.rejected_title'
                                  : 'verification.pending_title'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                  ),
                            ),
                            const SizedBox(height: AppConstants.spacingXs),
                            Text(
                              context.tr(rejected
                                  ? 'verification.rejected_subtitle'
                                  : 'verification.pending_subtitle'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppConstants.fontSizeSm,
                                color: isDark
                                    ? AppTheme.darkSecondaryText
                                    : AppTheme.lightSecondaryText,
                              ),
                            ),

                            // Admin's rejection note
                            if (rejected && _note.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacingMd),
                              Container(
                                padding: const EdgeInsets.all(AppConstants.paddingMd),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppTheme.darkError
                                          : AppTheme.lightError)
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusCard),
                                ),
                                child: Text(
                                  _note,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeSm,
                                    color: isDark
                                        ? AppTheme.darkError
                                        : AppTheme.lightError,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: AppConstants.spacingLg),

                            if (rejected)
                              AuthSubmitButton(
                                isLoading: false,
                                isDark:    isDark,
                                labelKey:  'verification.resubmit',
                                onPressed: _resubmit,
                              )
                            else ...[
                              const Center(
                                child: SizedBox(
                                  width:  24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingMd),
                              Text(
                                context.tr('verification.auto_refresh'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeCaption,
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      TextButton(
                        onPressed: _leaving ? null : _useAnotherAccount,
                        child: Text(context.tr('pin.use_another_account')),
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
