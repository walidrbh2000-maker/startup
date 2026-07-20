// lib/screens/home/widgets/worker_preview_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/localization.dart';
import '../../../utils/require_auth.dart';
import '../../../utils/whatsapp_launcher.dart';
import '../../../widgets/sheet_chrome.dart';
import 'online_badge.dart';
import 'rating_row.dart';
import 'worker_avatar.dart';

// ============================================================================
// WORKER PREVIEW SHEET — flat surface, no BackdropFilter
// ============================================================================

class WorkerPreviewSheet extends StatelessWidget {
  final WorkerModel worker;

  const WorkerPreviewSheet({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final theme  = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingLg,
          AppConstants.paddingMd,
          AppConstants.paddingLg,
          AppConstants.paddingLg,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl),
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppConstants.spacingMd),

              Row(
                children: [
                  WorkerAvatar(worker: worker, color: color),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(worker.name,
                                  style: theme.textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            // Business/Expert pack — "Pro" trust badge.
                            if (worker.searchPriority) ...[
                              const SizedBox(width: AppConstants.spacingXs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacingXs,
                                    vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusSm),
                                ),
                                child: Text(
                                  context.tr('worker_browse.pro_badge'),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkAccentText
                                        : color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: AppConstants.spacingXxs),
                        Text(
                          context.tr('services.${worker.profession}'),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.darkAccentText
                                  : color),
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        RatingRow(worker: worker),
                      ],
                    ),
                  ),
                  OnlineBadge(isOnline: worker.isOnline),
                ],
              ),

              const SizedBox(height: AppConstants.spacingLg),

              Row(
                children: [
                  Expanded(
                    child: _WhatsAppCTA(
                      phone:   worker.phoneNumber,
                      isDark:  isDark,
                      onPressed: () => context.pop(),
                      label:   context.tr('nav.messages'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        context.push('/worker/${worker.id}');
                      },
                      icon:  const Icon(AppIcons.profileOutlined, size: 18),
                      label: Text(context.tr('worker_preview.view_profile')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _WhatsAppCTA — white background, natural icon, green text
// ============================================================================

class _WhatsAppCTA extends ConsumerWidget {
  final String       phone;
  final bool         isDark;
  final String       label;
  final VoidCallback onPressed;

  const _WhatsAppCTA({
    required this.phone,
    required this.isDark,
    required this.label,
    required this.onPressed,
  });

  Future<void> _launch(BuildContext context, WidgetRef ref) async {
    // Contacting a worker is account-gated; guests get the create-account sheet.
    if (!await requireAuth(context, ref)) return;
    if (!context.mounted) return;
    // Capture before onPressed pops the sheet — the sheet's context (and this
    // widget) die with it, but the app-level messenger survives.
    final messenger = ScaffoldMessenger.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final failText  = context.tr('whatsapp.open_failed');
    final message   = context.tr('whatsapp.contact_message');
    onPressed();
    final ok = await launchWhatsApp(phone: phone, message: message);
    if (!ok) {
      messenger.showSnackBar(
        ErrorHandler.errorSnackBar(failText, isDark: isDark),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // whatsAppGreen is 1.97:1 on white — fails as text/border in light theme.
    // whatsAppDeep (7.7:1) exists for exactly this; green stays for dark.
    final ctaColor =
        isDark ? AppTheme.whatsAppGreen : AppTheme.whatsAppDeep;
    return SizedBox(
      height: AppConstants.buttonHeightMd,
      child: ElevatedButton(
        onPressed: () => _launch(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? AppTheme.darkSurfaceVariant
              : AppTheme.lightSurface,
          foregroundColor: ctaColor,
          elevation:       0,
          side: BorderSide(
            color: ctaColor.withValues(alpha: isDark ? 0.55 : 0.8),
            width: AppConstants.borderWidthDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingChipGap),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WhatsAppIcon(size: 20),
            const SizedBox(width: AppConstants.spacingSm),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ctaColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
