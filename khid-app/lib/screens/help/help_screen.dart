// lib/screens/help/help_screen.dart
//
// FAQ (expansion tiles) + a contact card. Shares AppSliverHeader (Point Final
// accent full stop) and AppSectionHeader with about/notifications.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/app_sliver_header.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/app_section_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static BoxDecoration _surface(bool isDark,
          {double radius = AppConstants.radiusLg}) =>
      BoxDecoration(
        color:        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: AppConstants.cardBorderWidth,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final theme   = Theme.of(context);
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            AppSliverHeader(
              title: context.tr('profile.help'),
            ),

            SliverPadding(
              padding: EdgeInsetsDirectional.only(
                top:    AppConstants.spacingMd,
                bottom: MediaQuery.paddingOf(context).bottom +
                    AppConstants.spacingXl,
                start:  AppConstants.paddingMd,
                end:    AppConstants.paddingMd,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  AppSectionHeader(label: context.tr('help.faq')),
                  const SizedBox(height: AppConstants.spacingSm),

                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q1'), answer: context.tr('help.faq_a1')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q2'), answer: context.tr('help.faq_a2')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q3'), answer: context.tr('help.faq_a3')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q4'), answer: context.tr('help.faq_a4')),
                  _FaqItem(isDark: isDark, question: context.tr('help.faq_q5'), answer: context.tr('help.faq_a5')),
                  const SizedBox(height: AppConstants.spacingXl),

                  AppSectionHeader(label: context.tr('help.contact')),
                  const SizedBox(height: AppConstants.spacingSm),

                  Container(
                    padding:    const EdgeInsets.all(AppConstants.spacingMdLg),
                    decoration: _surface(isDark),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('help.contact_body'),
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppConstants.spacingMd),
                        Semantics(
                          label:  context.tr('help.send_email'),
                          button: true,
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon:  const Icon(AppIcons.email),
                              label: Text(context.tr('help.send_email')),
                              onPressed: () async {
                                final uri = Uri.parse(
                                  'mailto:support@khidmeti.app?subject=Support%20Request',
                                );
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final bool   isDark;
  final String question;
  final String answer;

  const _FaqItem({
    required this.isDark,
    required this.question,
    required this.answer,
  });

  static BoxDecoration _surface(bool isDark) => BoxDecoration(
    color:        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
    borderRadius: BorderRadius.circular(AppConstants.radiusTile),
    border: Border.all(
      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      width: AppConstants.cardBorderWidth,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXxs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusTile),
        child: Container(
          decoration: _surface(isDark),
          child: ExpansionTile(
            backgroundColor:          Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            // Border() suppresses the ExpansionTile divider without a ThemeData clone.
            shape:          const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppConstants.paddingMd,
            ),
            childrenPadding: const EdgeInsetsDirectional.only(
              start:  AppConstants.paddingMd,
              end:    AppConstants.paddingMd,
              bottom: AppConstants.paddingMd,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            leading: Container(
              width:  AppConstants.iconContainerXl,
              height: AppConstants.iconContainerXl,
              decoration: BoxDecoration(
                color:        AppTheme.accentSelectedFill,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: Icon(
                AppIcons.help,
                color: theme.colorScheme.primary,
                size:  AppConstants.iconSizeSm,
              ),
            ),
            title: Text(
              question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize:   AppConstants.fontSizeTileLg,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Text(
                answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:  theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
