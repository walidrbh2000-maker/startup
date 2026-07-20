// lib/screens/service_request/widgets/priority_selector.dart

import 'package:flutter/material.dart';

import '../../../models/message_enums.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// PRIORITY SELECTOR
// Side-by-side "Normal / Urgent" cards with a radio dot indicator.
// ============================================================================

class PrioritySelector extends StatelessWidget {
  final ServicePriority selected;
  final bool isDark;
  final ValueChanged<ServicePriority> onChanged;

  const PrioritySelector({
    super.key,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PriorityCard(
            priority: ServicePriority.normal,
            isSelected: selected == ServicePriority.normal,
            isDark: isDark,
            cardColor: isDark ? AppTheme.priorityNormalDark : AppTheme.lightSuccess,
            icon: Icons.access_time_rounded,
            titleKey: 'request_form.priority_normal',
            descKey: 'request_form.priority_normal_desc',
            onTap: () => onChanged(ServicePriority.normal),
          ),
        ),
        const SizedBox(width: AppConstants.spacingMd),
        Expanded(
          child: _PriorityCard(
            priority: ServicePriority.urgent,
            isSelected: selected == ServicePriority.urgent,
            isDark: isDark,
            cardColor: isDark ? AppTheme.warningAmber : AppTheme.lightWarning,
            icon: Icons.bolt_rounded,
            titleKey: 'request_form.priority_urgent',
            descKey: 'request_form.priority_urgent_desc',
            onTap: () => onChanged(ServicePriority.urgent),
          ),
        ),
      ],
    );
  }
}

// ── Single priority card ──────────────────────────────────────────────────────

class _PriorityCard extends StatelessWidget {
  final ServicePriority priority;
  final bool isSelected;
  final bool isDark;
  final Color cardColor;
  final IconData icon;
  final String titleKey;
  final String descKey;
  final VoidCallback onTap;

  const _PriorityCard({
    required this.priority,
    required this.isSelected,
    required this.isDark,
    required this.cardColor,
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(titleKey),
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animDurationMicro,
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          decoration: BoxDecoration(
            color: isSelected
                ? cardColor.withValues(alpha: 0.09)
                : (isDark
                    ? AppTheme.darkSurface.withValues(alpha: 0.55)
                    : AppTheme.lightSurface),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isSelected
                  ? cardColor.withValues(alpha: 0.55)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.07)),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + radio row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          cardColor.withValues(alpha: isSelected ? 0.18 : 0.10),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSm),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: cardColor
                          .withValues(alpha: isSelected ? 1.0 : 0.60),
                    ),
                  ),
                  const Spacer(),
                  // Radio dot
                  AnimatedContainer(
                    duration: AppConstants.animDurationMicro,
                    width:  AppConstants.radioOuterSize,
                    height: AppConstants.radioOuterSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? cardColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? cardColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.20)
                                : Colors.black.withValues(alpha: 0.18)),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width:  AppConstants.radioInnerSize,
                              height: AppConstants.radioInnerSize,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                context.tr(titleKey),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? (isDark
                              ? cardColor
                              : (priority == ServicePriority.urgent
                                  ? AppTheme.amberTextLight
                                  : AppTheme.greenTextLight))
                          : (isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr(descKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
