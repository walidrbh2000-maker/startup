// lib/screens/auth/widgets/country_code_picker.dart
//
// Bottom sheet country selector.
// DZ (Algeria) is always first and visually separated from the rest.
// Filtered in-place with a debounced search field.
// Returns a [CountryCode] via Navigator.pop.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/search_bar.dart';
import '../../../widgets/sheet_chrome.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class CountryCode {
  final String flag;
  final String code;
  final String dialCode;
  final String name;

  /// National significant number length range (no leading zero) — drives the
  /// input cap and the submit gate. A single hardcoded 9 rejected valid TN/MR
  /// (8-digit) and DE/EG/US (10+) numbers.
  final int minDigits;
  final int maxDigits;

  const CountryCode({
    required this.flag,
    required this.code,
    required this.dialCode,
    required this.name,
    this.minDigits = 9,
    this.maxDigits = 9,
  });
}

const List<CountryCode> _kCountries = [
  CountryCode(flag: '🇩🇿', code: 'DZ', dialCode: '+213', name: 'Algérie'),
  CountryCode(flag: '🇲🇦', code: 'MA', dialCode: '+212', name: 'Maroc'),
  CountryCode(flag: '🇹🇳', code: 'TN', dialCode: '+216', name: 'Tunisie', minDigits: 8, maxDigits: 8),
  CountryCode(flag: '🇱🇾', code: 'LY', dialCode: '+218', name: 'Libye', minDigits: 9, maxDigits: 9),
  CountryCode(flag: '🇲🇷', code: 'MR', dialCode: '+222', name: 'Mauritanie', minDigits: 8, maxDigits: 8),
  CountryCode(flag: '🇫🇷', code: 'FR', dialCode: '+33',  name: 'France'),
  CountryCode(flag: '🇧🇪', code: 'BE', dialCode: '+32',  name: 'Belgique', minDigits: 8, maxDigits: 9),
  CountryCode(flag: '🇨🇭', code: 'CH', dialCode: '+41',  name: 'Suisse'),
  CountryCode(flag: '🇩🇪', code: 'DE', dialCode: '+49',  name: 'Allemagne', minDigits: 10, maxDigits: 11),
  CountryCode(flag: '🇬🇧', code: 'GB', dialCode: '+44',  name: 'Royaume-Uni', minDigits: 10, maxDigits: 10),
  CountryCode(flag: '🇺🇸', code: 'US', dialCode: '+1',   name: 'États-Unis', minDigits: 10, maxDigits: 10),
  CountryCode(flag: '🇨🇦', code: 'CA', dialCode: '+1',   name: 'Canada', minDigits: 10, maxDigits: 10),
  CountryCode(flag: '🇪🇸', code: 'ES', dialCode: '+34',  name: 'Espagne'),
  CountryCode(flag: '🇮🇹', code: 'IT', dialCode: '+39',  name: 'Italie', minDigits: 9, maxDigits: 10),
  CountryCode(flag: '🇵🇹', code: 'PT', dialCode: '+351', name: 'Portugal'),
  CountryCode(flag: '🇳🇱', code: 'NL', dialCode: '+31',  name: 'Pays-Bas'),
  CountryCode(flag: '🇸🇦', code: 'SA', dialCode: '+966', name: 'Arabie saoudite'),
  CountryCode(flag: '🇦🇪', code: 'AE', dialCode: '+971', name: 'Émirats arabes unis'),
  CountryCode(flag: '🇪🇬', code: 'EG', dialCode: '+20',  name: 'Égypte', minDigits: 10, maxDigits: 10),
  CountryCode(flag: '🇸🇳', code: 'SN', dialCode: '+221', name: 'Sénégal'),
];

const CountryCode kDefaultCountry = CountryCode(
  flag:     '🇩🇿',
  code:     'DZ',
  dialCode: '+213',
  name:     'Algérie',
);

// ─────────────────────────────────────────────────────────────────────────────
// Public helper
// ─────────────────────────────────────────────────────────────────────────────

Future<CountryCode?> showCountryCodePicker(BuildContext context) {
  return showModalBottomSheet<CountryCode>(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    builder:            (_) => const _CountryPickerSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {

  final TextEditingController _searchCtrl = TextEditingController();
  Timer?  _debounce;
  String  _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<CountryCode> get _filtered {
    if (_query.trim().isEmpty) return _kCountries;
    final q = _query.trim().toLowerCase();
    return _kCountries.where((c) =>
      c.name.toLowerCase().contains(q) ||
      c.code.toLowerCase().contains(q) ||
      c.dialCode.contains(q)
    ).toList();
  }

  bool get _isFiltered => _query.trim().isNotEmpty;

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.animDurationShort, () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.50,
      maxChildSize:     0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXxl),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingSm),
            const SheetHandle(),
            const SizedBox(height: AppConstants.spacingMd),

            // ── Title + close ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        context.tr('auth.phone'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SheetCloseButton(
                    semanticsLabel: context.tr('common.close'),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ── Search bar (simple — text only, no voice/camera) ───────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: AppSearchBar(
                controller: _searchCtrl,
                hintText:   context.tr('common.search'),
                onChanged:  _onSearch,
                isDark:     isDark,
              ),
            ),

            const SizedBox(height: AppConstants.spacingSm),

            // ── Country list ───────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptySearch(isDark: isDark)
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingLg,
                        0,
                        AppConstants.paddingLg,
                        AppConstants.paddingLg,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) {
                        if (!_isFiltered && index == 0) {
                          return Divider(
                            height:    20,
                            thickness: 0.5,
                            color: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder,
                          );
                        }
                        return const SizedBox(height: 4);
                      },
                      itemBuilder: (_, index) => _CountryTile(
                        country: filtered[index],
                        isDark:  isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context, filtered[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country tile
// ─────────────────────────────────────────────────────────────────────────────

class _CountryTile extends StatelessWidget {
  final CountryCode  country;
  final bool         isDark;
  final VoidCallback onTap;

  const _CountryTile({
    required this.country,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  '${country.name} ${country.dialCode}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: AppConstants.tileHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            child: Row(
              children: [
                Text(
                  country.flag,
                  style: const TextStyle(fontSize: AppConstants.emojiIconSize),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    country.name,
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeMd,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                ),
                Text(
                  country.dialCode,
                  style: TextStyle(
                    fontSize:   AppConstants.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty search state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final bool isDark;
  const _EmptySearch({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Text(
          context.tr('home.search_no_results'),
          style: TextStyle(
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
        ),
      ),
    );
  }
}
