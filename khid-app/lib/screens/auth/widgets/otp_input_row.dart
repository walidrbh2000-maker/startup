// lib/screens/auth/widgets/otp_input_row.dart
//
// 6-box OTP input. Boxes are sized by LayoutBuilder so the row fits any
// card width. Auto-advance on entry, backspace to previous, paste handling,
// auto-submit when full, oneTimeCode autofill on the first box.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ─────────────────────────────────────────────────────────────────────────────

/// Gap between individual OTP boxes (dp).
const double _kOtpGap = 6.0;

/// Height of each OTP box (dp). Width is computed dynamically.
const double _kOtpBoxHeight = 54.0;

// ─────────────────────────────────────────────────────────────────────────────

class OtpInputRow extends StatefulWidget {
  /// Called when all 6 digits are entered.
  final ValueChanged<String> onCompleted;

  /// Called on every digit change.
  final VoidCallback? onChanged;

  /// Whether to show error styling.
  final bool hasError;

  const OtpInputRow({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
  });

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  static const int _length = AppConstants.otpLength;

  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Clears all boxes and focuses the first one.
  void clear() {
    for (final c in _controllers) c.clear();
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  /// Returns the digits currently entered (may be fewer than 6).
  String get currentCode => _controllers.map((c) => c.text).join();

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _onChanged(int index, String value) {
    // Handle paste — value may contain multiple digits
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length == _length) {
        _autofillAll(digits);
        return;
      }
      // Partial paste — fill from current position
      final chars = digits.split('');
      for (int i = 0; i < chars.length && (index + i) < _length; i++) {
        _controllers[index + i].text = chars[i];
      }
      final nextIndex = (index + chars.length).clamp(0, _length - 1);
      _focusNodes[nextIndex].requestFocus();
      _notifyChange();
      return;
    }

    if (value.isEmpty) return;

    // Single digit — advance to next
    if (index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    _notifyChange();
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey != LogicalKeyboardKey.backspace) return;
    if (_controllers[index].text.isNotEmpty) return;
    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _notifyChange();
    }
  }

  void _autofillAll(String digits) {
    for (int i = 0; i < _length; i++) {
      _controllers[i].text = digits[i];
    }
    _focusNodes.last.unfocus();
    _notifyChange();
    widget.onCompleted(digits);
  }

  void _notifyChange() {
    setState(() {});
    widget.onChanged?.call();
    final code = currentCode;
    if (code.length == _length) {
      widget.onCompleted(code);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Digit sequence must render left-to-right even under an RTL locale —
    // the code the SMS shows is LTR, and mixing directions breaks the
    // auto-advance mental model. The Semantics label stays localized.
    return Semantics(
      label: '${context.tr('phone_auth.otp_title')} — $_length',
      textDirection: TextDirection.ltr,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
        builder: (context, constraints) {
          final totalGapWidth = (_length - 1) * _kOtpGap;
          final boxWidth =
              (constraints.maxWidth - totalGapWidth) / _length;

          return Row(
            children: List.generate(_length, (index) {
              final box = SizedBox(
                width: boxWidth,
                height: _kOtpBoxHeight,
                child: _OtpBox(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  isDark: isDark,
                  hasError: widget.hasError,
                  isFirst: index == 0,
                  onChanged: (v) => _onChanged(index, v),
                  onKeyEvent: (e) => _onKeyEvent(index, e),
                ),
              );

              if (index < _length - 1) {
                return [box, SizedBox(width: _kOtpGap)];
              }
              return [box];
            }).expand((e) => e).toList(),
          );
        },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual box
// ─────────────────────────────────────────────────────────────────────────────

class _OtpBox extends StatefulWidget {
  final TextEditingController  controller;
  final FocusNode              focusNode;
  final bool                   isDark;
  final bool                   hasError;
  final bool                   isFirst;
  final ValueChanged<String>   onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.hasError,
    required this.isFirst,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  // Owned by the state so it is created once and disposed — an inline
  // FocusNode in build() leaks a node on every rebuild.
  final FocusNode _keyListenerNode = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _keyListenerNode.dispose();
    super.dispose();
  }

  // Border color resolves state; width stays constant so focus never
  // shifts layout.
  Color get _borderColor {
    if (widget.hasError) {
      return widget.isDark ? AppTheme.darkError : AppTheme.lightError;
    }
    if (_isFocused) {
      return widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    }
    if (widget.controller.text.isNotEmpty) {
      return (widget.isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
          .withValues(alpha: 0.45);
    }
    return widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
  }

  Color get _fillColor {
    if (_isFocused) {
      return widget.isDark
          ? AppTheme.darkAccent.withValues(alpha: 0.06)
          : AppTheme.lightAccent.withValues(alpha: 0.04);
    }
    return widget.isDark
        ? AppTheme.darkSurfaceVariant
        : AppTheme.lightSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animDurationMicro,
      decoration: BoxDecoration(
        color: _fillColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: _borderColor,
          width: AppConstants.borderWidthDefault,
        ),
      ),
      child: KeyboardListener(
        focusNode: _keyListenerNode,
        onKeyEvent: widget.onKeyEvent,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofillHints:
              widget.isFirst ? const [AutofillHints.oneTimeCode] : null,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2, // Allow paste detection via >1 length
          showCursor: true,
          style: TextStyle(
            fontSize: AppConstants.fontSizeXxl,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            counterText: '',
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
