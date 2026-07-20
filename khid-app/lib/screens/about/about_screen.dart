// lib/screens/about/about_screen.dart
//
// App identity + legal/contact links. Sliver header (accent point-final via
// AppSliverHeader), logo mark, description, and external link rows.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/app_sliver_header.dart';
import '../../utils/localization.dart';
import '../../utils/system_ui_overlay.dart';
import '../../widgets/app_section_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
    final accent  = theme.colorScheme.primary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            AppSliverHeader(
              title: context.tr('profile.about'),
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

                  Center(
                    child: Column(
                      children: [
                        Container(
                          width:  AppConstants.iconSizeHero,
                          height: AppConstants.iconSizeHero,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                            color:        accent,
                            boxShadow: [
                              BoxShadow(
                                // Soft colored lift, not a neon halo — matches the
                                // app-wide "subtle elevation" shadow direction.
                                color:      accent.withValues(alpha: 0.22),
                                blurRadius: 20,
                                offset:     const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            AppIcons.homeRepair,
                            size:  AppConstants.iconSizeMdLg,
                            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        Text(
                          context.tr('common.app_name'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingXs),
                        Text(
                          '${context.tr('profile.version')} ${AppConstants.appVersion}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXl),

                  Container(
                    padding:    const EdgeInsets.all(AppConstants.paddingMd),
                    decoration: _surface(isDark),
                    child: Text(
                      context.tr('about.description'),
                      style:     theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  AppSectionHeader(label: context.tr('about.legal')),
                  const SizedBox(height: AppConstants.spacingSm),

                  _LinkTile(isDark: isDark, icon: AppIcons.privacy,
                      label: context.tr('about.privacy_policy'),
                      url: 'https://khidmeti.app/privacy'),
                  _LinkTile(isDark: isDark, icon: AppIcons.terms,
                      label: context.tr('about.terms'),
                      url: 'https://khidmeti.app/terms'),
                  _LinkTile(isDark: isDark, icon: AppIcons.code,
                      label: context.tr('about.open_source'),
                      url: 'https://khidmeti.app/licenses'),
                  const SizedBox(height: AppConstants.spacingMdLg),

                  AppSectionHeader(label: context.tr('about.contact')),
                  const SizedBox(height: AppConstants.spacingSm),

                  _LinkTile(isDark: isDark, icon: AppIcons.email,
                      label: context.tr('about.contact_email'),
                      url: 'mailto:support@khidmeti.app'),
                  const SizedBox(height: AppConstants.spacingXl),

                  Center(
                    child: Text(
                      context.tr('about.copyright'),
                      style:     theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
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

class _LinkTile extends StatelessWidget {
  final bool     isDark;
  final IconData icon;
  final String   label;
  final String   url;

  const _LinkTile({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.url,
  });

  Future<void> _launch() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One restrained icon colour — no rainbow chips (matches settings rows).
    final mutedIcon =
        isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    return Semantics(
      label:  label,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spacingXxs),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusTile),
          child: InkWell(
            onTap:        _launch,
            borderRadius: BorderRadius.circular(AppConstants.radiusTile),
            child: Container(
              height:  AppConstants.tileHeight,
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppConstants.paddingMd),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusTile),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: AppConstants.cardBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:  AppConstants.iconContainerXl,
                    height: AppConstants.iconContainerXl,
                    decoration: BoxDecoration(
                      color: mutedIcon.withValues(
                          alpha: AppConstants.opacityIconBgAlt),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(icon, color: mutedIcon,
                        size: AppConstants.iconSizeSm),
                  ),
                  const SizedBox(width: AppConstants.spacingTileInner),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize:   AppConstants.fontSizeTileLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(AppIcons.openInNew,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
