// lib/screens/edit_profile/edit_profile_screen.dart
//
// Point Final layout: editorial left-aligned header (accent rule + large
// headline over a muted section subtitle), flat avatar ring (no glow orb),
// small-caps section labels, and a flat become-worker card (no gradient).
// Scaffold.backgroundColor uses colorScheme.surface deliberately (flat sheet).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/error_handler.dart';
import '../../widgets/back_button.dart';
import '../../widgets/feature_error_state.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/wordmark.dart';
import '../../utils/localization.dart';
import '../../utils/media_path_helper.dart';
import '../../utils/system_ui_overlay.dart';
import '../../utils/validation_form.dart';
import '../../providers/edit_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameFocus  = FocusNode();
  final _phoneFocus = FocusNode();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onDataLoaded(EditProfileState state) {
    _nameCtrl.text  = state.name;
    _phoneCtrl.text = state.phone;
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source:       ImageSource.gallery,
      maxWidth:     AppConstants.avatarMaxDimensionPx,
      maxHeight:    AppConstants.avatarMaxDimensionPx,
      imageQuality: AppConstants.avatarImageQuality,
    );
    if (file != null && mounted) {
      setState(() => _pickedImagePath = file.path);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(editProfileProvider.notifier).save(
      name:         _nameCtrl.text,
      phone:        _phoneCtrl.text,
      newImagePath: _pickedImagePath,
    );

    if (!mounted) return;
    if (success) {
      ErrorHandler.showSuccessSnackBar(
        context,
        context.tr('profile.save_success'),
      );
      appBack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EditProfileState>(editProfileProvider, (prev, next) {
      if (prev?.status == EditProfileStatus.loading &&
          next.status == EditProfileStatus.idle) {
        _onDataLoaded(next);
      }
    });

    final state  = ref.watch(editProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor:        Theme.of(context).colorScheme.surface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          // Opaque so scrolling content masks under the in-bar title.
          backgroundColor:        Theme.of(context).colorScheme.surface,
          elevation:              0,
          scrolledUnderElevation: 0,
          centerTitle:            false,
          title:   PointFinalTitle(context.tr('profile.edit_profile')),
          leading: const AppBarBackButton(),
        ),
        body: switch (state.status) {
          EditProfileStatus.loading => const _LoadingView(),
          EditProfileStatus.error   => _ErrorView(
              message: state.errorMessage,
              onRetry: () => ref.read(editProfileProvider.notifier).retry(),
            ),
          _ => _FormView(
              state:           state,
              isDark:          isDark,
              formKey:         _formKey,
              nameCtrl:        _nameCtrl,
              phoneCtrl:       _phoneCtrl,
              nameFocus:       _nameFocus,
              phoneFocus:      _phoneFocus,
              pickedImagePath: _pickedImagePath,
              isSaving:        state.status == EditProfileStatus.saving,
              onPickImage:     _pickImage,
              onSave:          _save,
            ),
        },
      ),
    );
  }
}

// ============================================================================
// PRIVATE — FORM VIEW
// ============================================================================

class _FormView extends StatelessWidget {
  final EditProfileState      state;
  final bool                  isDark;
  final GlobalKey<FormState>  formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final FocusNode             nameFocus;
  final FocusNode             phoneFocus;
  final String?               pickedImagePath;
  final bool                  isSaving;
  final VoidCallback          onPickImage;
  final VoidCallback          onSave;

  const _FormView({
    required this.state,
    required this.isDark,
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.nameFocus,
    required this.phoneFocus,
    required this.pickedImagePath,
    required this.isSaving,
    required this.onPickImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: ListView(
        padding: EdgeInsetsDirectional.only(
          top:    MediaQuery.paddingOf(context).top +
              kToolbarHeight +
              AppConstants.spacingLg,
          bottom: MediaQuery.paddingOf(context).bottom +
              AppConstants.spacingXl,
          start:  AppConstants.paddingLg,
          end:    AppConstants.paddingLg,
        ),
        children: [
          // Title lives in the AppBar row beside the back button (PointFinalTitle).

          // ── Identity section ─────────────────────────────────────────────
          AppSectionHeader(label: context.tr('profile.section_identity')),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Avatar picker — flat ring, no glow orb ──────────────────────────
          Center(
            child: Semantics(
              label:  context.tr('profile.change_photo'),
              button: true,
              child: GestureDetector(
                onTap: isSaving ? null : onPickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width:  AppConstants.avatarSizeXl,
                      height: AppConstants.avatarSizeXl,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _AvatarImage(
                          pickedPath: pickedImagePath,
                          networkUrl: state.profileImageUrl,
                          name:       state.name,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 0,
                      end:    0,
                      child: Container(
                        width:  30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        child: const Icon(AppIcons.cameraRounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller:      nameCtrl,
                  focusNode:       nameFocus,
                  textInputAction: TextInputAction.next,
                  enabled:         !isSaving,
                  maxLength:       AppConstants.maxUsernameLength,
                  autofillHints:   const [AutofillHints.name],
                  onFieldSubmitted: (_) => phoneFocus.requestFocus(),
                  validator: (v) => FormValidators.validateUsername(v, context),
                  decoration: InputDecoration(
                    labelText:  context.tr('profile.full_name'),
                    prefixIcon: const Icon(AppIcons.person),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                TextFormField(
                  controller:      phoneCtrl,
                  focusNode:       phoneFocus,
                  textInputAction: TextInputAction.done,
                  enabled:         !isSaving,
                  keyboardType:    TextInputType.phone,
                  autofillHints:   const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                  ],
                  validator: (v) => FormValidators.validatePhone(v, context),
                  decoration: InputDecoration(
                    labelText:  context.tr('profile.phone_number'),
                    prefixIcon: const Icon(AppIcons.phone),
                  ),
                ),
              ],
            ),
          ),

          if (state.isWorkerAccount && state.professionLabel != null) ...[
            const SizedBox(height: AppConstants.spacingXl),
            AppSectionHeader(label: context.tr('profile.section_account')),
            const SizedBox(height: AppConstants.spacingMd),
            _ReadOnlyField(
              label:   context.tr('profile.profession'),
              value:   context.tr('services.${state.professionLabel}'),
              icon:    AppIcons.jobs,
              isDark:  isDark,
              caption: context.tr('profile.profession_change_note'),
            ),
          ],
          const SizedBox(height: AppConstants.spacingXl),

          Semantics(
            label:  context.tr('profile.save_changes'),
            button: true,
            child: SizedBox(
              width:  double.infinity,
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? SizedBox(
                        width:  AppConstants.spinnerSizeLg,
                        height: AppConstants.spinnerSizeLg,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:       theme.colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        context.tr('profile.save_changes'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),

          // ── Upgrade to worker (clients only) ────────────────────────────────
          if (!state.isWorkerAccount) ...[
            const SizedBox(height: AppConstants.spacingXl),
            _BecomeWorkerCard(isDark: isDark),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// _BecomeWorkerCard — entry point for the client→worker upgrade flow.
// Reuses the worker setup screen; on submit the account becomes a worker and
// gains the worker tabs (jobs, story modal, worker home).
// ============================================================================

class _BecomeWorkerCard extends StatelessWidget {
  final bool isDark;
  const _BecomeWorkerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final accent  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final text    = isDark ? AppTheme.darkText : AppTheme.lightText;
    final subtext = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Semantics(
      button: true,
      label: context.tr('profile.become_worker_title'),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.workerProfileSetup),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: AppConstants.cardBorderWidth,
            ),
          ),
          child: Row(
            children: [
              // Accent edge rule — the hairline motif, vertical.
              Container(
                width:  3,
                height: 52,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadiusDirectional.horizontal(
                    end: Radius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMd),
              Icon(AppIcons.jobs, color: accent, size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('profile.become_worker_title'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXxs),
                      Text(
                        context.tr('profile.become_worker_subtitle'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: subtext,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
              const SizedBox(width: AppConstants.paddingMd),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE — AVATAR IMAGE (storedPath → proxy URL via MediaPathHelper.toUrl)
// ============================================================================

class _AvatarImage extends StatelessWidget {
  final String? pickedPath;
  final String? networkUrl;
  final String  name;

  const _AvatarImage({
    required this.pickedPath,
    required this.networkUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    if (pickedPath != null) {
      return Image.file(
        File(pickedPath!),
        fit:          BoxFit.cover,
        errorBuilder: (_, __, ___) => _Initials(name: name),
      );
    }
    final emojiChar = MediaPathHelper.emoji(networkUrl);
    if (emojiChar != null) {
      return Container(
        color:     Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: Text(emojiChar, style: const TextStyle(fontSize: 40)),
      );
    }
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      final displayUrl = MediaPathHelper.toUrl(
        networkUrl,
        apiBaseUrl: AppConfig.apiBaseUrl,
      );
      if (displayUrl.isEmpty) return _Initials(name: name);

      return Image.network(
        displayUrl,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _Initials(name: name),
        errorBuilder: (_, __, ___) => _Initials(name: name),
      );
    }
    return _Initials(name: name);
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      color:     Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize:   28,
          fontWeight: FontWeight.w700,
          color:      Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE — READ-ONLY FIELD
// ============================================================================

class _ReadOnlyField extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final bool     isDark;
  final String?  caption;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical:   AppConstants.spacingTileInner,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: AppConstants.cardBorderWidth,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant,
                  size: AppConstants.iconSizeSm),
              const SizedBox(width: AppConstants.spacingSmMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXxs),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.password,
                size:  AppConstants.iconSizeXs,
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppConstants.spacingXs),
          Padding(
            padding: const EdgeInsetsDirectional.only(
                start: AppConstants.paddingXs),
            child: Text(
              caption!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// PRIVATE — LOADING / ERROR VIEWS
// ============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}

class _ErrorView extends StatelessWidget {
  final String?      message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => FeatureErrorState(
        isDark:     Theme.of(context).brightness == Brightness.dark,
        errorTitle: context.tr('common.error'),
        message:    message != null
            ? context.tr(message!)
            : context.tr('errors.unknown'),
        onRetry:    onRetry,
        retryLabel: context.tr('common.retry'),
      );
}
