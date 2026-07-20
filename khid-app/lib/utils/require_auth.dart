// lib/utils/require_auth.dart
//
// The single account-gate for guest mode. Call it at the entry of any action
// that needs a real account (open profile, contact a worker, bid, request a
// service, subscribe, go online). One function, one prompt — not scattered
// `if (isGuest)` checks.
//
//   if (!await requireAuth(context, ref)) return;   // aborts guests

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/core_providers.dart';
import '../widgets/app_bottom_sheet.dart';
import 'constants.dart';
import 'localization.dart';

/// Returns true when the user has a real account (proceed). For a guest, shows
/// a "create account" sheet and returns false — the caller must abort.
Future<bool> requireAuth(BuildContext context, WidgetRef ref) async {
  if (!ref.read(isGuestProvider)) return true;

  await showModalBottomSheet<void>(
    context:         context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => AppBottomSheet(
      title: context.tr('auth.guest_gate_title'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMd,
            vertical:   AppConstants.spacingSm,
          ),
          child: Text(
            context.tr('auth.guest_gate_body'),
            textAlign: TextAlign.center,
            style: Theme.of(sheetCtx).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMd),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(sheetCtx).pop();
                // Drop the anonymous session; the router then routes to phone
                // auth. A guest has no data, so nothing is lost by signing out.
                ref.read(authServiceProvider).signOut();
              },
              child: Text(context.tr('auth.guest_gate_cta')),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
      ],
    ),
  );
  return false;
}
