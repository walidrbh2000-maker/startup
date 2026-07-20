// lib/models/user_check_result.dart
//
// Data contract for GET /auth/check?uid=:uid (AuthController NestJS).
//
// Response shape (from auth.service.ts → UserCheckResult):
//   { isNewUser: boolean, role: string | null }
//
// isNewUser == true  → no MongoDB profile → redirect to /role-selection
// isNewUser == false → profile exists     → redirect to /home

class UserCheckResult {
  /// True when no MongoDB profile exists for the Firebase UID.
  /// Safe default on error: treat as new user (setup screen upserts safely).
  final bool isNewUser;

  /// 'client' | 'worker' when isNewUser == false, null otherwise.
  final String? role;

  /// Account has an optional anti-SIM-recycling PIN configured.
  final bool hasPin;

  /// This device must pass POST /auth/verify-pin before any other API call.
  final bool pinRequired;

  const UserCheckResult({
    required this.isNewUser,
    this.role,
    this.hasPin             = false,
    this.pinRequired        = false,
    this.verificationStatus = '',
    this.verificationNote   = '',
  });

  /// '' (approved) | 'pending' | 'rejected'. Non-empty parks the user on the
  /// pending-approval screen until an admin clears it.
  final String verificationStatus;

  /// Admin's rejection note (shown on the pending screen so the user can fix).
  final String verificationNote;

  factory UserCheckResult.fromJson(Map<String, dynamic> json) {
    return UserCheckResult(
      isNewUser:   json['isNewUser']   as bool? ?? true,
      role:        json['role']        as String?,
      hasPin:      json['hasPin']      as bool? ?? false,
      pinRequired: json['pinRequired'] as bool? ?? false,
      verificationStatus: json['verificationStatus'] as String? ?? '',
      verificationNote:   json['verificationNote']   as String? ?? '',
    );
  }

  /// True when the account submitted documents and is awaiting/denied approval.
  bool get needsApproval =>
      verificationStatus == 'pending' || verificationStatus == 'rejected';

  /// Safe default: treat unknown state as new user.
  static const UserCheckResult newUser =
      UserCheckResult(isNewUser: true, role: null);

  @override
  String toString() =>
      'UserCheckResult(isNewUser: $isNewUser, role: $role, '
      'hasPin: $hasPin, pinRequired: $pinRequired, '
      'verificationStatus: $verificationStatus)';
}
