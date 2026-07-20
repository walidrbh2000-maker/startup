// lib/screens/auth/widgets/document_picker_widget.dart
//
// Verification-document picker for the worker (optional) and business
// (mandatory) profile setup screens. Picks PDFs or images via file_picker,
// shows each picked file as a removable chip. Upload happens at submit time
// (ProfileSetupController._uploadDocuments), not here.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class DocumentPickerWidget extends StatefulWidget {
  /// Picked local file paths (from ProfileSetupState.documentPaths).
  final List<String> documentPaths;

  /// Called with newly picked paths — the controller merges + dedupes.
  final ValueChanged<List<String>> onPicked;

  /// Called with the index of a chip's remove button.
  final ValueChanged<int> onRemoved;

  /// Business: documents are mandatory — copy says "required" instead of
  /// "optional" and the section is visually emphasized when empty.
  final bool required;

  const DocumentPickerWidget({
    super.key,
    required this.documentPaths,
    required this.onPicked,
    required this.onRemoved,
    this.required = false,
  });

  @override
  State<DocumentPickerWidget> createState() => _DocumentPickerWidgetState();
}

class _DocumentPickerWidgetState extends State<DocumentPickerWidget> {
  bool _picking = false;

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
      );
      if (result == null) return; // user cancelled
      final paths = result.paths.whereType<String>().toList();
      if (paths.isNotEmpty) widget.onPicked(paths);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String _fileName(String path) {
    final i = path.lastIndexOf('/');
    return i == -1 ? path : path.substring(i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Semantics(
          header: true,
          child: Text(
            context.tr(widget.required
                ? 'verification.docs_label_required'
                : 'verification.docs_label_optional'),
            style: TextStyle(
              fontSize:   AppConstants.fontSizeCaption,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          context.tr('verification.docs_hint'),
          style: TextStyle(
            fontSize: AppConstants.fontSizeSm,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Picked file chips
        if (widget.documentPaths.isNotEmpty) ...[
          Wrap(
            spacing:    AppConstants.spacingSm,
            runSpacing: AppConstants.spacingSm,
            children: [
              for (int i = 0; i < widget.documentPaths.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSm,
                    vertical:   AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusCircle),
                    border: Border.all(
                      color: accent,
                      width: AppConstants.borderWidthDefault,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.documentPaths[i]
                                .toLowerCase()
                                .endsWith('.pdf')
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        size:  AppConstants.iconSizeSm,
                        color: accent,
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          _fileName(widget.documentPaths[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize:   AppConstants.fontSizeSm,
                            fontWeight: FontWeight.w600,
                            color:      accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Semantics(
                        button: true,
                        label:  context.tr('common.delete'),
                        child: GestureDetector(
                          onTap: () => widget.onRemoved(i),
                          child: Icon(
                            Icons.close_rounded,
                            size:  AppConstants.iconSizeSm,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // Add button
        Semantics(
          button: true,
          label:  context.tr('verification.add_document'),
          child: OutlinedButton.icon(
            onPressed: _picking ? null : _pick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(context.tr('verification.add_document')),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(
                color: accent,
                width: AppConstants.borderWidthDefault,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
                vertical:   AppConstants.paddingMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
