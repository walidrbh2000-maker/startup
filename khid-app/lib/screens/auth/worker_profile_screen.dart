// lib/screens/auth/worker_profile_screen.dart
//
// Worker profile SETUP screen — shown once to new users who chose the
// "worker" role. Distinct from lib/screens/worker_profile/worker_profile_screen.dart
// (the public worker profile viewer).
//
// The router's redirect doesn't fire after submit (no Firebase auth state
// change — the user is already signed in), so navigation is explicit:
// cache the role, then go to /subscription.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile_setup_state.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_setup_controller.dart';
import '../../providers/user_role_provider.dart';
import '../../providers/worker_home_controller.dart';
import '../../providers/worker_jobs_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/back_button.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/avatar_picker_widget.dart';
import 'widgets/document_picker_widget.dart';
import 'widgets/profession_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────

/// New-user worker profile setup. Called after role selection.
class WorkerProfileSetupScreen extends ConsumerStatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  ConsumerState<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState
    extends ConsumerState<WorkerProfileSetupScreen>
    with SingleTickerProviderStateMixin {

  final _nameCtrl  = TextEditingController();
  final _nameFocus = FocusNode();

  late final AnimationController _slideCtrl;
  late final Animation<double>    _fade;
  late final Animation<Offset>    _slide;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync:    this,
      duration: AppConstants.authCardEntranceDuration,
    )..forward();
    _fade  = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    ref.read(profileSetupControllerProvider.notifier).setName(_nameCtrl.text);

    final success =
        await ref.read(profileSetupControllerProvider.notifier).submitWorkerProfile();

    if (success && mounted) {
      // Cache the role so MainNavigationScreen shows the worker tab bar
      // immediately.
      setCachedUserRole(
        ref.read(cachedUserRoleProvider.notifier),
        UserRole.worker,
        force: true,
      );
      // Re-init the worker providers so an upgrading client (whose worker
      // streams were empty) picks up the freshly-created worker document.
      ref.invalidate(workerHomeControllerProvider);
      ref.invalidate(workerJobsControllerProvider);

      // Documents submitted → the account is in admin review; every API call
      // now answers APPROVAL_PENDING. Park on the pending screen.
      if (ref.read(profileSetupControllerProvider.notifier).submittedForApproval) {
        ref.read(approvalGateProvider.notifier).state = true;
        context.go(AppRoutes.pendingApproval);
        return;
      }

      // Offre d'abonnement de visibilité à l'inscription (skippable → /home).
      context.go(AppRoutes.subscription);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(profileSetupControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // Reached with go() from role selection (empty stack — back falls back
      // there so a mis-tapped role is recoverable) or push() from
      // edit_profile (client upgrading — back pops normally).
      child: AppBackGuard(
        fallback: AppRoutes.roleSelection,
        child: Scaffold(
          body: Stack(
            children: [
              AuthBackground(isDark: isDark),
              SafeArea(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left:   AppConstants.paddingLg,
                            right:  AppConstants.paddingLg,
                            top:    AppConstants.paddingXl,
                            bottom: MediaQuery.viewInsetsOf(context).bottom +
                                    AppConstants.paddingXl,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([

                              // Back — role selection or the pushing screen.
                              Row(
                                children: [
                                  AppBackButton(
                                    isDark:    isDark,
                                    onPressed: () => appBack(
                                      context,
                                      fallback: AppRoutes.roleSelection,
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.spacingMd),
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        context.tr('worker_profile.title'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppTheme.darkText
                                                  : AppTheme.lightText,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppConstants.spacingXs),

                              Text(
                                context.tr('worker_profile.subtitle'),
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeMd,
                                  color: isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                ),
                              ),

                              const SizedBox(height: AppConstants.spacingXl),

                              // ── Avatar ─────────────────────────────────────
                              AvatarPickerWidget(
                                selectedImagePath: state.avatarLocalPath,
                                selectedEmoji:     state.avatarEmoji,
                                onImagePathSelected: (path) => ref
                                    .read(profileSetupControllerProvider.notifier)
                                    .setAvatarPath(path),
                                onEmojiSelected: (emoji) => ref
                                    .read(profileSetupControllerProvider.notifier)
                                    .setAvatarEmoji(emoji ?? '👷'),
                              ),

                              if (state.status ==
                                  ProfileSetupStatus.uploadingImage) ...[
                                const SizedBox(height: AppConstants.spacingMd),
                                LinearProgressIndicator(
                                  value: state.uploadProgress,
                                  backgroundColor:
                                      accent.withValues(alpha: 0.20),
                                  valueColor:      AlwaysStoppedAnimation(accent),
                                ),
                              ],

                              const SizedBox(height: AppConstants.spacingXl),

                              // ── Name field ─────────────────────────────────
                              AutofillGroup(
                                child: TextFormField(
                                  controller:         _nameCtrl,
                                  focusNode:          _nameFocus,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction:    TextInputAction.done,
                                  autofillHints:      const [AutofillHints.name],
                                  maxLength:          AppConstants.maxUsernameLength,
                                  onChanged: (v) => ref
                                      .read(profileSetupControllerProvider.notifier)
                                      .setName(v),
                                  decoration: InputDecoration(
                                    labelText:   context.tr('profile.full_name'),
                                    prefixIcon:  const Icon(AppIcons.person),
                                    counterText: '',
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppConstants.spacingXl),

                              // ── Profession section label ───────────────────
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      context.tr('register.service_label'),
                                      style: TextStyle(
                                        fontSize:   AppConstants.fontSizeCaption,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppTheme.darkSecondaryText
                                            : AppTheme.lightSecondaryText,
                                      ),
                                    ),
                                  ),
                                  if (state.profession != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingSm,
                                        vertical:   AppConstants.spacingXxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentSelectedFill,
                                        borderRadius: BorderRadius.circular(
                                          AppConstants.radiusCircle,
                                        ),
                                      ),
                                      child: Text(
                                        // Raw key → localized label, same as
                                        // edit_profile does for this value.
                                        context.tr(
                                            'services.${state.profession!}'),
                                        style: TextStyle(
                                          fontSize:   AppConstants.fontSizeSm,
                                          fontWeight: FontWeight.w600,
                                          color:      accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: AppConstants.spacingMd),

                              // ── Profession picker ──────────────────────────
                              ProfessionPicker(
                                selectedKey: state.profession,
                                onSelected: (key) {
                                  if (key != null) {
                                    ref
                                        .read(profileSetupControllerProvider
                                            .notifier)
                                        .setProfession(key);
                                  } else {
                                    ref
                                        .read(profileSetupControllerProvider
                                            .notifier)
                                        .clearProfession();
                                  }
                                },
                              ),

                              // ── Verification documents (optional) ──────────
                              const SizedBox(height: AppConstants.spacingXl),
                              DocumentPickerWidget(
                                documentPaths: state.documentPaths,
                                onPicked: (paths) => ref
                                    .read(profileSetupControllerProvider.notifier)
                                    .addDocumentPaths(paths),
                                onRemoved: (i) => ref
                                    .read(profileSetupControllerProvider.notifier)
                                    .removeDocumentAt(i),
                              ),

                              // ── Error ──────────────────────────────────────
                              if (state.hasError && state.errorKey != null) ...[
                                const SizedBox(height: AppConstants.spacingMd),
                                Text(
                                  context.tr(state.errorKey!),
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeSm,
                                    color: isDark
                                        ? AppTheme.darkError
                                        : AppTheme.lightError,
                                  ),
                                ),
                              ],

                              const SizedBox(height: AppConstants.spacingXl),

                              // ── CTA ────────────────────────────────────────
                              AuthSubmitButton(
                                isLoading: state.isLoading,
                                isDark:    isDark,
                                onPressed: (!state.isLoading &&
                                        state.canSubmitWorker)
                                    ? _submit
                                    : null,
                                labelKey: 'worker_profile.cta',
                              ),

                              const SizedBox(height: AppConstants.spacingMd),
                            ]),
                          ),
                        ),
                      ],
                    ),
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
