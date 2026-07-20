// lib/screens/service_request/widgets/service_selection_row.dart

// Horizontal scrollable chip row for service type selection.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profession_model.dart';
import '../../../providers/professions_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'service_selection_sheet.dart';

// ─── Local dimensions ─────────────────────────────────────────────────────────
const double _kCardW = 72.0;
const double _kCardH = 80.0;

// ─────────────────────────────────────────────────────────────────────────────

class ServiceSelectionRow extends ConsumerWidget {
  final String?              selected;
  final bool                 isDark;
  final Color                accentColor;
  final ValueChanged<String> onServiceSelected;

  const ServiceSelectionRow({
    super.key,
    required this.selected,
    required this.isDark,
    required this.accentColor,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionsAsync = ref.watch(professionsProvider);

    final List<ProfessionModel> professions = professionsAsync.maybeWhen(
      data:      (data) => data.where((p) => p.isActive).take(7).toList(),
      orElse:    ()     => kDefaultProfessions.take(7).toList(),
    );

    return SizedBox(
      height: _kCardH,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ...professions.map((profession) {
            return Padding(
              padding: const EdgeInsets.only(right: AppConstants.spacingChipGap),
              child: _ServiceChip(
                profession: profession,
                isActive:   selected == profession.key,
                isDark:     isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onServiceSelected(profession.key);
                },
              ),
            );
          }),

          // "See all" chip
          _AllServicesChip(
            isDark:            isDark,
            accentColor:       accentColor,
            selected:          selected,
            onServiceSelected: onServiceSelected,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service chip
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceChip extends StatelessWidget {
  final ProfessionModel profession;
  final bool            isActive;
  final bool            isDark;
  final VoidCallback    onTap;

  const _ServiceChip({
    required this.profession,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final icon  = AppTheme.getProfessionIcon(profession.key);

    return Semantics(
      button:   true,
      label:    profession.label,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _kCardW,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppConstants.animDurationMicro,
                curve:    Curves.easeOutCubic,
                width:    AppConstants.categoryTileIconSize,
                height:   AppConstants.categoryTileIconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? color.withValues(alpha: isDark ? 0.24 : 0.15)
                      : color.withValues(alpha: isDark ? 0.12 : 0.09),
                  border: isActive
                      ? Border.all(color: color.withValues(alpha: 0.45), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isActive
                        ? color
                        : color.withValues(alpha: isDark ? 0.75 : 0.65),
                    size: AppConstants.iconSizeSm,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingSm),

              Text(
                profession.label,
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeXxs,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? (isDark ? AppTheme.darkAccentText : color)
                      : (isDark
                          ? AppTheme.darkText
                          : AppTheme.lightSecondaryText),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "All services" chip
// ─────────────────────────────────────────────────────────────────────────────

class _AllServicesChip extends StatelessWidget {
  final bool                 isDark;
  final Color                accentColor;
  final String?              selected;
  final ValueChanged<String> onServiceSelected;

  const _AllServicesChip({
    required this.isDark,
    required this.accentColor,
    required this.selected,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:  context.tr('home.see_all'),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ServiceSelectionSheet.show(
            context,
            selected:          selected,
            onServiceSelected: onServiceSelected,
          );
        },
        child: SizedBox(
          width: _kCardW,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width:  AppConstants.categoryTileIconSize,
                height: AppConstants.categoryTileIconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(AppIcons.gridView, color: accentColor, size: AppConstants.iconSizeSm),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                context.tr('home.see_all'),
                style: TextStyle(
                  fontSize:   AppConstants.fontSizeXxs,
                  fontWeight: FontWeight.w600,
                  color:      accentColor,
                  height:     1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
