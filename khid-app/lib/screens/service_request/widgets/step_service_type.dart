// lib/screens/service_request/widgets/step_service_type.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'date_time_picker_pill.dart';
import 'schedule_pill.dart';
import 'service_selection_row.dart';

// ============================================================================
// STEP 1 — WHAT DO YOU NEED?
// Horizontal circular chip row (mirrors HomeServiceGrid) + "Tout voir" sheet
// + schedule pills + date/time pickers.
// All business logic delegated to callbacks; zero state or logic here.
// ============================================================================

class StepServiceType extends StatelessWidget {
  final String? selected;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<String> onServiceSelected;
  final VoidCallback onAsap;
  final VoidCallback onTodayEvening;
  final VoidCallback onTomorrow;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const StepServiceType({
    super.key,
    required this.selected,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.isDark,
    required this.accentColor,
    required this.onServiceSelected,
    required this.onAsap,
    required this.onTodayEvening,
    required this.onTomorrow,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  // ── Schedule detection helpers ────────────────────────────────────────────

  /// ASAP = scheduled date+time falls within [now, now + 2h] — not merely on
  /// today's calendar date (so "today at 23:59" does not count as ASAP).
  bool get _isAsap {
    final now = DateTime.now();
    final scheduled = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    final twoHoursFromNow = now.add(const Duration(hours: 2));
    // Active if scheduled is in the past (already overdue ASAP) or within 2h.
    // The exact today-18:00 slot belongs to the "Ce soir" pill — from 16:00
    // onward it would otherwise satisfy both and light two pills at once.
    return !scheduled.isAfter(twoHoursFromNow) && !_isTodayEvening;
  }

  bool get _isTodayEvening {
    final now = DateTime.now();
    return scheduledDate.day == now.day &&
        scheduledDate.month == now.month &&
        scheduledDate.year == now.year &&
        scheduledTime.hour == 18 &&
        scheduledTime.minute == 0;
  }

  bool get _isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return scheduledDate.day == tomorrow.day &&
        scheduledDate.month == tomorrow.month &&
        scheduledDate.year == tomorrow.year;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppConstants.paddingMd,
        AppConstants.spacingMd,
        AppConstants.paddingMd,
        AppConstants.spacingXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Headline ──────────────────────────────────────────────
          Text(
            context.tr('request_form.section_service'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            context.tr('request_form.subtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Circular chip row — mirrors HomeServiceGrid ───────────
          ServiceSelectionRow(
            selected: selected,
            isDark: isDark,
            accentColor: accentColor,
            onServiceSelected: onServiceSelected,
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // ── When? section ─────────────────────────────────────────
          Text(
            context.tr('request_form.section_when'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Full-width schedule pills ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: SchedulePill(
                  label: context.tr('request_form.schedule_asap'),
                  subLabel: context.tr('request_form.schedule_asap_sub'),
                  icon: Icons.bolt_rounded,
                  isActive: _isAsap,
                  accentColor: accentColor,
                  isDark: isDark,
                  onTap: onAsap,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Expanded(
                child: SchedulePill(
                  label: context.tr('request_form.schedule_today_evening'),
                  subLabel: context.tr('request_form.schedule_today_sub'),
                  icon: Icons.wb_twilight_rounded,
                  isActive: _isTodayEvening,
                  accentColor: accentColor,
                  isDark: isDark,
                  onTap: onTodayEvening,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Expanded(
                child: SchedulePill(
                  label: context.tr('request_form.schedule_tomorrow'),
                  subLabel: context.tr('request_form.schedule_tomorrow_sub'),
                  icon: Icons.calendar_today_rounded,
                  isActive: _isTomorrow,
                  accentColor: accentColor,
                  isDark: isDark,
                  onTap: onTomorrow,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // ── Date + Time pickers ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: DateTimePickerPill(
                  icon: Icons.calendar_today_rounded,
                  label: context.tr('requests.scheduled_date'),
                  value: DateFormat('EEE, d MMM',
                      Localizations.localeOf(context).languageCode)
                      .format(scheduledDate),
                  isDark: isDark,
                  accentColor: accentColor,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) onDateChanged(picked);
                  },
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: DateTimePickerPill(
                  icon: Icons.access_time_rounded,
                  label: context.tr('requests.scheduled_time'),
                  value: scheduledTime.format(context),
                  isDark: isDark,
                  accentColor: accentColor,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: scheduledTime,
                    );
                    if (picked != null) onTimeChanged(picked);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
