// lib/screens/worker_jobs/widgets/complete_job_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class CompleteJobResult {
  final String? notes;
  final double? price;

  const CompleteJobResult({this.notes, this.price});
}

class CompleteJobDialog extends StatefulWidget {
  const CompleteJobDialog({super.key});

  static Future<CompleteJobResult?> show(BuildContext context) {
    return showDialog<CompleteJobResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const CompleteJobDialog(),
    );
  }

  @override
  State<CompleteJobDialog> createState() => _CompleteJobDialogState();
}

class _CompleteJobDialogState extends State<CompleteJobDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusXxl),
        child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingXl),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(AppConstants.radiusXxl),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkTileBorder
                    : AppTheme.lightTileBorder,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.onlineGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.task_alt_rounded,
                          color: AppTheme.onlineGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('worker_jobs.complete_job_title'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              context.tr('worker_jobs.complete_job_subtitle'),
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppTheme.darkSecondaryText
                                            : AppTheme.lightSecondaryText,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingXl),

                  // Notes field
                  Text(
                    context.tr('worker_jobs.complete_notes_label'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: context.tr('worker_jobs.complete_notes_hint'),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Price field
                  Text(
                    context.tr('worker_jobs.complete_price_label'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: context.tr('worker_jobs.complete_price_hint'),
                      prefixText: '${context.tr('common.currency')} ',
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final price = double.tryParse(val);
                        if (price == null || price <= 0) {
                          return context
                              .tr('worker_jobs.complete_price_invalid');
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppConstants.spacingXl),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: context.tr('common.cancel'),
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.tr('common.cancel')),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingMd),
                      Expanded(
                        flex: 2,
                        child: Semantics(
                          button: true,
                          label: context.tr('worker_jobs.mark_complete'),
                          child: ElevatedButton(
                            onPressed: _onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.onlineGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(context.tr('worker_jobs.mark_complete')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    final price = _priceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_priceCtrl.text.trim());
    Navigator.pop(context, CompleteJobResult(notes: notes, price: price));
  }
}
