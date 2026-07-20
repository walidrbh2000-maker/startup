// lib/screens/auth/user_profile_screen.dart
//
// Client profile setup. Called after role selection for new users.
// Business accounts (?type=business) additionally attach mandatory
// verification documents and land on /pending-approval after submit.
//
// The router's redirect doesn't fire after submit (no Firebase auth state
// change — the user is already signed in), so navigation is explicit:
// cache the role, then go to /home.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile_setup_state.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_setup_controller.dart';
import '../../providers/user_role_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/back_button.dart';
import 'widgets/auth_background.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/avatar_picker_widget.dart';
import 'widgets/document_picker_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    ref.read(profileSetupControllerProvider.notifier).setName(_nameCtrl.text);

    // 'business' when arriving from the B2B role card; 'client' otherwise.
    final accountRole =
        GoRouterState.of(context).uri.queryParameters['type'] == 'business'
            ? 'business'
            : 'client';

    final success = await ref
        .read(profileSetupControllerProvider.notifier)
        .submitClientProfile(accountRole: accountRole);

    if (success && mounted) {
      // Cache the role so MainNavigationScreen shows the correct tab bar
      // immediately.
      setCachedUserRole(
        ref.read(cachedUserRoleProvider.notifier),
        UserRole.client,
        force: true,
      );

      // Business submitted documents → account is in admin review; park on
      // the pending screen until an admin approves.
      if (ref.read(profileSetupControllerProvider.notifier).submittedForApproval) {
        ref.read(approvalGateProvider.notifier).state = true;
        context.go(AppRoutes.pendingApproval);
        return;
      }

      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(profileSetupControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    // Business accounts (B2B role card) must attach verification documents.
    final isBusiness =
        GoRouterState.of(context).uri.queryParameters['type'] == 'business';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      // Setup screens are reached with go() (empty stack) — back returns to
      // role selection so a mis-tapped role is recoverable, both via the
      // header button and the system gesture.
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
                          // Back to role selection (mis-tapped role).
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
                                    context.tr('user_profile.title'),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppConstants.spacingXs),

                          Text(
                            context.tr('user_profile.subtitle'),
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeMd,
                              color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                            ),
                          ),

                          const SizedBox(height: AppConstants.spacingXl),

                          // Avatar
                          AvatarPickerWidget(
                            selectedImagePath: state.avatarLocalPath,
                            selectedEmoji:     state.avatarEmoji,
                            onImagePathSelected: (path) =>
                                ref.read(profileSetupControllerProvider.notifier)
                                   .setAvatarPath(path),
                            onEmojiSelected: (emoji) =>
                                ref.read(profileSetupControllerProvider.notifier)
                                   .setAvatarEmoji(emoji ?? '👤'),
                          ),

                          // Upload progress
                          if (state.status == ProfileSetupStatus.uploadingImage) ...[
                            const SizedBox(height: AppConstants.spacingMd),
                            LinearProgressIndicator(
                              value: state.uploadProgress,
                              backgroundColor: accent.withValues(alpha: 0.20),
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                          ],

                          const SizedBox(height: AppConstants.spacingXl),

                          // Name field
                          AutofillGroup(
                            child: TextFormField(
                              controller:       _nameCtrl,
                              focusNode:        _nameFocus,
                              textCapitalization: TextCapitalization.words,
                              textInputAction:  TextInputAction.done,
                              autofillHints:    const [AutofillHints.name],
                              maxLength:        AppConstants.maxUsernameLength,
                              onChanged: (v) =>
                                  ref.read(profileSetupControllerProvider.notifier)
                                     .setName(v),
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: context.tr('profile.full_name'),
                                prefixIcon: const Icon(AppIcons.person),
                                counterText: '',
                              ),
                            ),
                          ),

                          // Business: mandatory verification documents.
                          if (isBusiness) ...[
                            const SizedBox(height: AppConstants.spacingXl),
                            DocumentPickerWidget(
                              required:      true,
                              documentPaths: state.documentPaths,
                              onPicked: (paths) => ref
                                  .read(profileSetupControllerProvider.notifier)
                                  .addDocumentPaths(paths),
                              onRemoved: (i) => ref
                                  .read(profileSetupControllerProvider.notifier)
                                  .removeDocumentAt(i),
                            ),
                          ],

                          // Error
                          if (state.hasError && state.errorKey != null) ...[
                            const SizedBox(height: AppConstants.spacingSm),
                            Text(
                              context.tr(state.errorKey!),
                              style: TextStyle(
                                fontSize: AppConstants.fontSizeSm,
                                color: isDark ? AppTheme.darkError : AppTheme.lightError,
                              ),
                            ),
                          ],

                          const SizedBox(height: AppConstants.spacingXl),

                          // CTA
                          AuthSubmitButton(
                            isLoading: state.isLoading,
                            isDark:    isDark,
                            onPressed: (!state.isLoading &&
                                    (isBusiness
                                        ? state.canSubmitBusiness
                                        : state.isNameValid))
                                ? _submit
                                : null,
                            labelKey:  'user_profile.cta',
                          ),

                          const SizedBox(height: AppConstants.spacingMd),

                          // Skip avatar link
                          if (!state.hasAvatar)
                            Center(
                              child: Semantics(
                                button: true,
                                label: context.tr('onboarding.skip'),
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(profileSetupControllerProvider.notifier)
                                       .setAvatarEmoji('👤');
                                  },
                                  child: Text(
                                    context.tr('user_profile.skip_avatar'),
                                    style: TextStyle(
                                      fontSize:   AppConstants.fontSizeSm,
                                      color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
