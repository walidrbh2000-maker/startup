// lib/screens/home/widgets/home_categories_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../utils/profession_resolver.dart';
import '../../../widgets/search_bar.dart';
import '../../../widgets/sheet_chrome.dart';

class HomeCategoriesSheet extends StatefulWidget {
  final ValueChanged<String?> onFilterChanged;

  const HomeCategoriesSheet({super.key, required this.onFilterChanged});

  static void show(
    BuildContext context,
    ValueChanged<String?> onFilterChanged,
  ) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => HomeCategoriesSheet(onFilterChanged: onFilterChanged),
    );
  }

  @override
  State<HomeCategoriesSheet> createState() => _HomeCategoriesSheetState();
}

class _HomeCategoriesSheetState extends State<HomeCategoriesSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  late List<_CategoryItem> _allItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allItems = _buildAllItems(context);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_CategoryItem> _buildAllItems(BuildContext context) => [
    _CategoryItem(ServiceType.plumbing,
        context.tr('services.plumber'),          AppIcons.plumbing),
    _CategoryItem(ServiceType.electrical,
        context.tr('services.electrician'),      AppIcons.electrical),
    _CategoryItem(ServiceType.cleaning,
        context.tr('services.cleaner'),          AppIcons.cleaning),
    _CategoryItem(ServiceType.painting,
        context.tr('services.painter'),          AppIcons.painting),
    _CategoryItem(ServiceType.carpentry,
        context.tr('services.carpenter'),        AppIcons.carpentry),
    _CategoryItem(ServiceType.airConditioning,
        context.tr('services.ac_repair'),        AppIcons.airConditioning),
    _CategoryItem(ServiceType.gardening,
        context.tr('services.gardener'),         AppIcons.gardening),
    _CategoryItem(ServiceType.appliances,
        context.tr('services.appliance_repair'), AppIcons.appliances),
  ];

  List<_CategoryItem> get _filtered {
    if (_query.isEmpty) return _allItems;
    final q = _query.toLowerCase();
    final labelMatches   = _allItems.where((i) => i.label.toLowerCase().contains(q)).toSet();
    final resolvedType   = ProfessionResolver.resolve(_query);
    final resolverMatches = resolvedType != null
        ? _allItems.where((i) => i.type == resolvedType).toSet()
        : <_CategoryItem>{};
    final matchedTypes = {...labelMatches, ...resolverMatches}.map((i) => i.type).toSet();
    return _allItems.where((i) => matchedTypes.contains(i.type)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl  = Directionality.of(context) == TextDirection.rtl;
    final items  = _filtered;

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

            // ── Title row ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('home.all_services'),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight:    FontWeight.w700,
                        letterSpacing: isRtl ? 0.0 : -0.3,
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

            // ── Search bar (simple — text + ProfessionResolver, no voice) ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLg,
              ),
              child: AppSearchBar(
                controller: _searchCtrl,
                hintText:   context.tr('home.search_service'),
                onChanged:  (v) => setState(() => _query = v),
                isDark:     isDark,
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),

            // ── Category grid ──────────────────────────────────────────────
            Expanded(
              child: items.isEmpty
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
                      itemCount: items.length,
                      itemBuilder: (_, i) => _CategoryTile(
                        item:   items[i],
                        isDark: isDark,
                        onTap:  () {
                          HapticFeedback.lightImpact();
                          widget.onFilterChanged(items[i].type);
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

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final _CategoryItem item;
  final bool          isDark;
  final VoidCallback  onTap;

  const _CategoryTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Semantics(
      button: true,
      label:  item.label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  AppConstants.categoryTileIconSize,
              height: AppConstants.categoryTileIconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isDark ? 0.12 : 0.09),
              ),
              child: Icon(
                item.icon,
                color: color.withValues(alpha: isDark ? 0.85 : 0.75),
                size:  AppConstants.iconSizeMd,
              ),
            ),
            SizedBox(height: AppConstants.cardIconLabelGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXs,
              ),
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkText
                      : AppTheme.lightSecondaryText,
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
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _CategoryItem {
  final String   type;
  final String   label;
  final IconData icon;
  const _CategoryItem(this.type, this.label, this.icon);
}
