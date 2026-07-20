// lib/models/profile_setup_state.dart
//
// State for the profile setup flow, shared between:
//   - UserProfileScreen  (client)
//   - WorkerProfileScreen (worker)
//
// The controller branches on [isWorker] to decide which API endpoint to call.

import 'package:equatable/equatable.dart';

// ── Status ────────────────────────────────────────────────────────────────────

enum ProfileSetupStatus {
  idle,
  uploadingImage,
  submitting,
  success,
  error,
}

// ── State ─────────────────────────────────────────────────────────────────────

class ProfileSetupState extends Equatable {
  final ProfileSetupStatus status;

  /// Display name entered by the user.
  final String name;

  /// Local file path of a picked image — null means no image selected yet.
  final String? avatarLocalPath;

  /// Emoji avatar key ('👷', '👩', etc.) — alternative to a real photo.
  final String? avatarEmoji;

  /// Selected profession key — workers only.
  final String? profession;

  /// Local file paths of picked verification documents (PDF or image).
  /// Optional for workers, mandatory for business accounts.
  final List<String> documentPaths;

  /// Upload progress 0.0–1.0 — displayed in the image upload progress bar.
  final double uploadProgress;

  /// Localization key for current error.
  final String? errorKey;

  const ProfileSetupState({
    this.status           = ProfileSetupStatus.idle,
    this.name             = '',
    this.avatarLocalPath,
    this.avatarEmoji,
    this.profession,
    this.documentPaths     = const [],
    this.uploadProgress    = 0.0,
    this.errorKey,
  });

  // ── Computed ────────────────────────────────────────────────────────────────

  bool get isLoading        => status == ProfileSetupStatus.uploadingImage
                            || status == ProfileSetupStatus.submitting;
  bool get hasError         => status == ProfileSetupStatus.error;
  bool get hasAvatar        => avatarLocalPath != null || avatarEmoji != null;
  bool get isNameValid      => name.trim().length >= 2;
  bool get hasDocuments     => documentPaths.isNotEmpty;
  bool get canSubmitClient  => isNameValid && !isLoading;
  bool get canSubmitWorker  => isNameValid && profession != null && !isLoading;
  /// Business accounts must attach at least one document before submitting.
  bool get canSubmitBusiness => isNameValid && hasDocuments && !isLoading;

  // ── copyWith ────────────────────────────────────────────────────────────────

  ProfileSetupState copyWith({
    ProfileSetupStatus? status,
    String?  name,
    String?  avatarLocalPath,
    String?  avatarEmoji,
    String?  profession,
    List<String>? documentPaths,
    double?  uploadProgress,
    String?  errorKey,
    bool     clearError          = false,
    bool     clearAvatar         = false,
    bool     clearProfession     = false,
  }) {
    return ProfileSetupState(
      status:            status            ?? this.status,
      name:              name              ?? this.name,
      avatarLocalPath:   clearAvatar  ? null : (avatarLocalPath ?? this.avatarLocalPath),
      avatarEmoji:       clearAvatar  ? null : (avatarEmoji     ?? this.avatarEmoji),
      profession:        clearProfession   ? null : (profession  ?? this.profession),
      documentPaths:     documentPaths     ?? this.documentPaths,
      uploadProgress:    uploadProgress    ?? this.uploadProgress,
      errorKey:          clearError ? null : (errorKey ?? this.errorKey),
    );
  }

  @override
  List<Object?> get props => [
    status, name, avatarLocalPath, avatarEmoji,
    profession, documentPaths, uploadProgress, errorKey,
  ];
}
