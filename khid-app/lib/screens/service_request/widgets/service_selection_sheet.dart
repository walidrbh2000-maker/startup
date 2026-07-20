// lib/screens/service_request/widgets/service_selection_sheet.dart

// Full-screen service type picker with search.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profession_model.dart';
import '../../../providers/professions_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/profession_resolver.dart';
import '../../../widgets/sheet_chrome.dart';

// ─────────────────────────────────────────────────────────────────────────────

class ServiceSelectionSheet extends ConsumerStatefulWidget {
  final String?              selected;
  final ValueChanged<String> onServiceSelected;

  const ServiceSelectionSheet({
    super.key,
    required this.selected,
    required this.onServiceSelected,
  });

  static void show(
    BuildContext context, {
    required String?              selected,
    required ValueChanged<String> onServiceSelected,
  }) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => ServiceSelectionSheet(
        selected:          selected,
        onServiceSelected: onServiceSelected,
      ),
    );
  }

  @override
  ConsumerState<ServiceSelectionSheet> createState() =>
      _ServiceSelectionSheetState();
}

class _ServiceSelectionSheetState
    extends ConsumerState<ServiceSelectionSheet> {

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProfessionModel> _filter(List<ProfessionModel> all) {
    if (_query.trim().isEmpty) return all;

    final q = _query.trim().toLowerCase();

    // Label match
    final labelMatches = all.where((p) =>
      p.label.toLowerCase().contains(q) ||
      p.key.toLowerCase().contains(q)
    ).toSet();

    // ProfessionResolver fuzzy match
    final resolvedKey = ProfessionResolver.resolve(_query);
    final resolverMatches = resolvedKey != null
        ? all.where((p) => p.key == resolvedKey).toSet()
        : <ProfessionModel>{};

    final combined = {...labelMatches, ...resolverMatches}.toList();
    combined.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final isRtl     = Directionality.of(context) == TextDirection.rtl;
    final accent    = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    final professionsAsync = ref.watch(professionsProvider);
    final allProfessions   = professionsAsync.maybeWhen(
      data:   (data) => data.where((p) => p.isActive).toList(),
      orElse: ()     => kDefaultProfessions,
    );
    final filtered = _filter(allProfessions);

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize:     0.45,
      maxChildSize:     0.95,
      builder: (_, controller) => Container(
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
            const SizedBox(height: AppConstants.spacingLg),

            // Title + close
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        context.tr('request_form.section_service'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight:    FontWeight.w700,
                          letterSpacing: isRtl ? 0.0 : -0.3,
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

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: Container(
                height: AppConstants.searchBarHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface.withValues(alpha: 0.60)
                      : AppTheme.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppConstants.spacingMd),
                    Icon(
                      AppIcons.search,
                      size:  AppConstants.iconSizeSm,
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged:  (v) => setState(() => _query = v),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                        ),
                        decoration: InputDecoration(
                          border:        InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText:      context.tr('home.search_service'),
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppTheme.darkSecondaryText
                                : AppTheme.lightSecondaryText,
                          ),
                          isDense:        true,
                          contentPadding: EdgeInsets.zero,
                          filled:         true,
                          fillColor:      Colors.transparent,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon:  const Icon(AppIcons.close, size: 16),
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // Grid
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        context.tr('home.no_service_found'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                      ),
                    )
                  : GridView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingLg,
                        0,
                        AppConstants.paddingLg,
                        AppConstants.paddingLg,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:   4,
                        mainAxisSpacing:  AppConstants.spacingMd,
                        crossAxisSpacing: AppConstants.spacingMd,
                        childAspectRatio: 0.82,
                      ),
                      itemCount:   filtered.length,
                      itemBuilder: (_, i) => _ServiceTile(
                        profession: filtered[i],
                        isSelected: widget.selected == filtered[i].key,
                        isDark:     isDark,
                        accent:     accent,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onServiceSelected(filtered[i].key);
                          Navigator.pop(context);
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
// Service tile
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  final ProfessionModel profession;
  final bool            isSelected;
  final bool            isDark;
  final Color           accent;
  final VoidCallback    onTap;

  const _ServiceTile({
    required this.profession,
    required this.isSelected,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final icon  = AppTheme.getProfessionIcon(profession.key);

    return Semantics(
      button:   true,
      label:    profession.label,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: AppConstants.animDurationMicro,
                  width:    AppConstants.categoryTileIconSize,
                  height:   AppConstants.categoryTileIconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? color.withValues(alpha: isDark ? 0.24 : 0.15)
                        : color.withValues(alpha: isDark ? 0.12 : 0.09),
                    border: isSelected
                        ? Border.all(
                            color: color.withValues(alpha: 0.55),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? color
                        : color.withValues(alpha: isDark ? 0.85 : 0.75),
                    size: AppConstants.iconSizeMd,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: -2,
                    right:  -2,
                    child: Container(
                      width:  16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBackground
                              : AppTheme.lightBackground,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size:  12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppConstants.spacingSm),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXs,
              ),
              child: Text(
                profession.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? (isDark ? AppTheme.darkAccentText : color)
                      : (isDark
                          ? AppTheme.darkText
                          : AppTheme.lightSecondaryText),
                  fontSize:   AppConstants.fontSizeXxs,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  height:     1.2,
                ),
                textAlign: TextAlign.center,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
