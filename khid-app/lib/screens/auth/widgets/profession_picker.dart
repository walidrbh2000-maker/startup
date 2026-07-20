// lib/screens/auth/widgets/profession_picker.dart
//
// Scalable profession picker — layout adapts to catalogue size:
//   ≤12 professions → plain grid
//   ≤24             → grid + search
//   more            → grid + search + category tabs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profession_model.dart';
import '../../../providers/professions_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../widgets/search_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ProfessionPicker extends ConsumerStatefulWidget {
  final String? selectedKey;
  final ValueChanged<String?> onSelected;

  const ProfessionPicker({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  ConsumerState<ProfessionPicker> createState() => _ProfessionPickerState();
}

class _ProfessionPickerState extends ConsumerState<ProfessionPicker> {
  final TextEditingController _searchCtrl = TextEditingController();

  Timer?  _debounce;
  String  _query            = '';
  String? _activeCategoryKey;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<ProfessionModel> _filter(List<ProfessionModel> all) {
    List<ProfessionModel> result = all.where((p) => p.isActive).toList();
    if (_activeCategoryKey != null) {
      result = result.where((p) => p.categoryKey == _activeCategoryKey).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result.where((p) =>
        p.label.toLowerCase().contains(q) ||
        p.key.toLowerCase().contains(q)
      ).toList();
    }
    return result..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  _Layout _layoutFor(int count) {
    if (count <= 12) return _Layout.gridSimple;
    if (count <= 24) return _Layout.gridWithSearch;
    return _Layout.groupedList;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final professions = ref.watch(professionsProvider);

    return professions.when(
      loading: () => const _LoadingGrid(),
      error:   (_, __) => _ErrorWidget(
        isDark:  isDark,
        onRetry: () => ref.invalidate(professionsProvider),
      ),
      data: (professions) {
        final allActive = professions.where((p) => p.isActive).toList();
        final layout    = _layoutFor(allActive.length);
        final filtered  = _filter(professions);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (layout != _Layout.gridSimple) ...[
              AppSearchBar(
                controller: _searchCtrl,
                hintText:   context.tr('common.search'),
                isDark:     isDark,
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(AppConstants.animDurationShort, () {
                    if (mounted) setState(() => _query = value);
                  });
                },
              ),
              const SizedBox(height: AppConstants.spacingSm),
            ],

            if (layout == _Layout.groupedList) ...[
              _CategoryTabs(
                all:        allActive,
                isDark:     isDark,
                activeKey:  _activeCategoryKey,
                onSelected: (key) => setState(() => _activeCategoryKey = key),
              ),
              const SizedBox(height: AppConstants.spacingMd),
            ],

            if (filtered.isEmpty)
              _EmptySearch(isDark: isDark)
            else
              GridView.builder(
                shrinkWrap: true,
                physics:    const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   4,
                  crossAxisSpacing: AppConstants.spacingChipGap,
                  mainAxisSpacing:  AppConstants.spacingChipGap,
                  childAspectRatio: 0.85,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final profession = filtered[index];
                  return _ProfessionTile(
                    profession: profession,
                    isSelected: widget.selectedKey == profession.key,
                    isDark:     isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onSelected(
                        widget.selectedKey == profession.key
                            ? null
                            : profession.key,
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum _Layout { gridSimple, gridWithSearch, groupedList }

// ─────────────────────────────────────────────────────────────────────────────
// Profession tile
// ─────────────────────────────────────────────────────────────────────────────

class _ProfessionTile extends StatelessWidget {
  final ProfessionModel profession;
  final bool            isSelected;
  final bool            isDark;
  final VoidCallback    onTap;

  const _ProfessionTile({
    required this.profession,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button:   true,
      selected: isSelected,
      label:    profession.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animDurationMicro,
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: isDark ? 0.20 : 0.12)
                : (isDark ? AppTheme.darkTileFill : AppTheme.lightTileFill),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark ? AppTheme.darkTileBorder : AppTheme.lightTileBorder),
              width: isSelected
                  ? AppConstants.borderWidthSelected
                  : AppConstants.borderWidthDefault,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    AppTheme.getProfessionIcon(profession.key),
                    size:  AppConstants.iconSizeMd,
                    color: isSelected
                        ? accent
                        : (isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText),
                  ),
                  if (isSelected)
                    Positioned(
                      right: -6,
                      top:   -6,
                      child: Container(
                        width:  16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBackground
                                : AppTheme.lightBackground,
                            width: AppConstants.borderWidthSelected,
                          ),
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingXs),
                child: Text(
                  profession.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? accent
                        : (isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tabs
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  final List<ProfessionModel> all;
  final bool                  isDark;
  final String?               activeKey;
  final ValueChanged<String?> onSelected;

  const _CategoryTabs({
    required this.all,
    required this.isDark,
    required this.activeKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final categories = <MapEntry<String, String>>[];
    for (final p in all) {
      if (seen.add(p.categoryKey)) {
        categories.add(MapEntry(p.categoryKey, p.categoryLabel));
      }
    }
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingXs),
            child: _CategoryChip(
              label:      context.tr('home.filter_all'),
              isSelected: activeKey == null,
              accent:     accent,
              isDark:     isDark,
              onTap:      () => onSelected(null),
            ),
          ),
          ...categories.map((e) => Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingXs),
            child: _CategoryChip(
              label:      e.value,
              isSelected: activeKey == e.key,
              accent:     accent,
              isDark:     isDark,
              onTap:      () => onSelected(activeKey == e.key ? null : e.key),
            ),
          )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String       label;
  final bool         isSelected;
  final Color        accent;
  final bool         isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button:   true,
      selected: isSelected,
      label:    label,
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        child: AnimatedContainer(
          duration: AppConstants.animDurationMicro,
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMd),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize:   AppConstants.fontSizeSm,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkText : AppTheme.lightText),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error / empty states
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics:    const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppConstants.spacingChipGap,
        mainAxisSpacing:  AppConstants.spacingChipGap,
        childAspectRatio: 0.85,
      ),
      itemCount: 8,
      itemBuilder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkTileFill : AppTheme.lightTileFill,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        );
      },
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final bool         isDark;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr('errors.network'),
          style: TextStyle(
            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        TextButton(onPressed: onRetry, child: Text(context.tr('common.retry'))),
      ],
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final bool isDark;
  const _EmptySearch({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXl),
        child: Text(
          context.tr('home.no_service_found'),
          style: TextStyle(
            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ),
      ),
    );
  }
}
