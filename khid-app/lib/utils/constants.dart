// TODO(S3-grid-audit): spacingTileInner (14dp), badgePaddingV (3dp), and
//   spacingXxs (2dp) are off the 4dp grid. No immediate visual regression —
//   schedule for next design-system alignment pass with designer sign-off.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  static const String appName    = 'Khidmeti';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'خدمات منزلية احترافية';
  static const String baseUrl    = 'https://api.khidmeti.com';

  static const int defaultPageSize = 20;
  static const int maxPageSize     = 100;

  static const double fabClearance = 80.0;
  static const double maxBidPrice  = 500000.0;

  static const Duration defaultTimeout  = Duration(seconds: 30);
  static const Duration longTimeout     = Duration(minutes: 2);
  static const Duration cacheExpiry     = Duration(hours: 1);

  /// Micro-interaction animation duration.
  static const Duration animDurationMicro = Duration(milliseconds: 200);

  // ── Animation duration tokens ─────────────────────────────────────────────

  /// Press-feedback micro animation.
  static const Duration animDurationPress = Duration(milliseconds: 100);

  /// Short transition — AnimatedSwitcher / map-fullscreen fades.
  static const Duration animDurationShort = Duration(milliseconds: 300);

  /// Page-turn duration for PageView.nextPage.
  static const Duration animDurationPageTurn = Duration(milliseconds: 380);

  /// Skeleton shimmer pulse period.
  static const Duration animDurationSkeletonPulse = Duration(milliseconds: 900);

  /// Delay before auto-redirecting off a dead screen
  /// (job-cancelled branch in job_detail_screen).
  static const Duration autoRedirectDelay = Duration(seconds: 3);

  /// Auth card entrance animation duration.
  static const Duration authCardEntranceDuration = Duration(milliseconds: 900);

  static const int biddingDeadlineMinutes  = 120;
  static const int maxPendingBidsPerWorker = 5;

  // Spacing
  // TODO(S3-grid-audit): spacingXxs (2dp) is off the 4dp grid.
  static const double spacingXxs  = 2.0;
  static const double spacingXs   = 4.0;
  static const double spacingSm   = 8.0;
  static const double spacingMd   = 16.0;
  static const double spacingLg   = 24.0;
  static const double spacingXl   = 32.0;
  static const double spacingMdLg = 20.0;

  /// Generic 12dp gap — between spacingSm (8) and spacingMd (16).
  /// For gaps that don't carry chip/section semantics.
  static const double spacingSmMd = 12.0;

  static const double spacingChipGap = 12.0;

  // Padding
  static const double paddingXs     = 4.0;
  static const double paddingSm     = 8.0;
  static const double paddingMd     = 16.0;
  static const double paddingLg     = 24.0;
  static const double paddingXl     = 32.0;
  static const double paddingInputV = 12.0;

  // Radius
  static const double radiusXs     = 4.0;
  static const double radiusSm     = 8.0;
  static const double radiusMd     = 12.0;
  static const double radiusLg     = 16.0;
  static const double radiusXl     = 20.0;
  static const double radiusXxl    = 24.0;
  static const double radiusCircle = 28.0;
  static const double radiusCard   = 20.0;
  static const double radiusTile   = 18.0;

  // Buttons
  static const double buttonHeight   = 54.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightSm = 44.0;

  /// Canonical FAB-area CTA button height (48dp).
  static const double buttonHeightFab = 48.0;

  /// Back button touch target size.
  static const double backButtonSize = 48.0;

  /// Canonical button label font size.
  static const double buttonFontSize = 15.0;

  // Cards
  static const double cardPadding      = 18.0;
  static const double cardBorderWidth  = 0.5;
  static const double accentBarWidth   = 3.0;
  static const double cardIconLabelGap = 8.0;

  // Inputs
  static const double inputRadius   = 14.0;
  static const double inputPaddingH = 18.0;
  static const double inputPaddingV = 15.0;

  // ── Navigation bar ────────────────────────────────────────────────────────
  //
  // Glass nav bar sizing model:
  //
  //   navPillHeight   = 58dp  — the visible pill widget height
  //   navBarMarginB   = 10dp  — bottom margin below the pill (above home indicator)
  //   navBarBottomGap = 12dp  — additional bottom clearance for SafeArea breathing room
  //   ──────────────────────────────────────────────────────────────────────
  //   navBarHeight    = 80dp  — total SizedBox height consumed in bottomNavigationBar
  //
  //   navBarScrollClearance = navBarHeight(80) + spacingMd(16) = 96dp
  //   → The canonical value to add to scroll body bottom padding so that
  //     the last card always appears ABOVE the floating nav pill with a
  //     comfortable 16dp gap. Any screen with SafeArea(bottom: false) and a
  //     NavigationBar must add viewPadding.bottom on top of this value.
  //
  /// Height of the glass pill widget itself.
  static const double navPillHeight = 58.0;

  /// Space below the pill (between pill bottom and device edge / home indicator).
  static const double navBarMarginB = 10.0;

  /// Additional bottom gap baked into the _NavShell SizedBox.
  /// Together with navPillHeight + navBarMarginB this forms navBarHeight.
  static const double navBarBottomGap = 12.0;

  /// Total height of the NavigationBar widget as rendered in
  /// Scaffold.bottomNavigationBar.
  /// = navPillHeight(58) + navBarMarginB(10) + navBarBottomGap(12) = 80dp.
  static const double navBarHeight = 80.0;

  /// Canonical scroll-body bottom clearance for screens that float above the
  /// NavigationBar.
  /// = navBarHeight(80) + spacingMd(16) = 96dp.
  /// Add MediaQuery.viewPaddingOf(context).bottom on top for per-device inset.
  ///
  /// Usage in SafeArea(bottom: false) scroll bodies:
  ///   SizedBox(height: AppConstants.navBarScrollClearance
  ///                  + MediaQuery.viewPaddingOf(context).bottom)
  static const double navBarScrollClearance = 96.0;

  static const double navBarRadius    = 24.0;
  static const double navBarMarginH   = 16.0;
  static const double navPillPaddingH = 14.0;
  static const double navPillPaddingV = 8.0;
  static const double navDotSize      = 4.0;

  // ── Hero section padding ──────────────────────────────────────────────────
  //
  // [HERO-FIX] heroPaddingTop:    38.0 → 8.0  (saves 30dp of dead space)
  // [HERO-FIX] heroPaddingBottom: 30.0 → 8.0  (saves 22dp of dead space)
  //
  // Together these lift every element in HomeScreen upward by 52dp so the
  // "Programmer une demande" CTA card clears the floating NavigationBar
  // in the default (at-rest, un-scrolled) position.
  //
  // This approach is preferred over adding a bottom buffer because it works
  // without requiring the user to scroll at all — the content simply starts
  // higher on screen. All inter-element spacings are completely unchanged.
  //
  // heroPaddingH (horizontal) is intentionally unchanged at 24dp.

  static const double heroPaddingTop    = 8.0;
  static const double heroPaddingH      = 24.0;
  static const double heroPaddingBottom = 8.0;

  // Sections
  static const double sectionLabelMB = 12.0;
  static const double sectionMT      = 24.0;
  static const double sectionCardGap = 12.0;

  // Badges / chips / tile gaps
  // TODO(S3-grid-audit): spacingTileInner (14dp) and badgePaddingV (3dp) are off-grid.
  static const double spacingTileInner = 14.0;
  static const double badgePaddingH    = 10.0;
  static const double badgePaddingV    = 3.0;
  static const double chipRadius       = 8.0;
  static const double chipPaddingH     = 10.0;
  static const double chipPaddingV     = 4.0;

  // ── Border widths ─────────────────────────────────────────────────────────
  static const double borderWidthDefault  = 1.0;
  static const double borderWidthSelected = 1.5;

  // Font sizes
  static const double heroFontSize    = 32.0;
  static const double fontSizeTileLg  = 15.0;
  static const double fontSizeXxs     = 11.0;
  /// NOTE: fontSizeXs = 10dp is below platform minimums. Use fontSizeXxs (11dp).
  static const double fontSizeXs      = 10.0;
  static const double fontSizeSm      = 12.0;
  static const double fontSizeCaption = 13.0;
  static const double fontSizeMd      = 14.0;
  static const double fontSizeLg      = 16.0;
  static const double fontSizeXl      = 18.0;
  static const double fontSizeXxl     = 20.0;
  static const double fontSizeDisplay = 24.0;
  static const double fontSizeAppBar  = 17.0;

  // Line heights
  static const double lineHeightTight = 1.4;

  // Icons
  static const double iconSizeXs   = 16.0;
  static const double iconSizeSm   = 20.0;
  static const double iconSizeMd   = 24.0;
  static const double iconSizeLg   = 32.0;
  /// 40dp glyph — between iconSizeLg (32) and iconSizeXl (48).
  /// (rating stars, about-screen logo glyph).
  static const double iconSizeMdLg  = 40.0;
  static const double iconSizeXl   = 48.0;
  static const double iconSizeLg2  = 64.0;
  static const double iconSizeHero = 80.0;

  // Container sizes
  static const double iconContainerSm         = 28.0;
  static const double iconContainerMd         = 32.0;
  static const double iconContainerLg         = 36.0;
  static const double iconContainerXl         = 40.0;
  static const double buttonIconSize          = 20.0;
  static const double iconContainerFeature    = 56.0;
  static const double serviceIconContainerSize = 40.0;
  static const double emojiIconSize           = 22.0;
  static const double spinnerSizeLg           = 20.0;
  static const double spinnerSizeSm           = 14.0;

  /// Thin progress/level bar radius (home worker section, voice sheet).
  static const double strengthBarRadius = 2.0;

  // ── Priority selector radio dots ──────────────────────────────────────────
  static const double radioOuterSize = 16.0;
  static const double radioInnerSize = 6.0;

  // ── Typography tokens ─────────────────────────────────────────────────────
  /// Monospace font family name — used for coordinate / technical displays.
  static const String monoFontFamily = 'monospace';

  static const double filterChipHeight   = 36.0;
  static const double filterChipPaddingV = 8.0;
  static const double locationDotMarker  = 40.0;
  static const int    maxEmailLength     = 254;

  // Sheet handle
  static const double sheetHandleWidth  = 40.0;
  static const double sheetHandleHeight = 4.0;

  static const int fallbackWorkerQueryLimit = 100;

  // Search / input
  static const double searchBarHeight      = 48.0;
  static const double categoryTileIconSize = 48.0;

  /// Canonical row height for SettingsTile, SignOutTile, _DeleteAccountTile.
  static const double tileHeight = 64.0;

  static const double settingsRetryButtonWidth  = 180.0;
  static const double profileCardSkeletonHeight = 110.0;

  // ── Toggle switch ─────────────────────────────────────────────────────────
  static const double toggleTrackW    = 40.0;
  static const double toggleTrackH    = 20.0;
  static const double toggleThumbSize = 16.0;
  static const double statusDotSize   =  8.0;

  // ── Map / location ────────────────────────────────────────────────────────
  static const double locationDotSize = 16.0;

  // ── Dimension tokens ──────────────────────────────────────────────────────

  /// Rating-screen worker avatar circle.
  static const double avatarSizeLg = 68.0;

  /// Edit-profile avatar picker circle.
  static const double avatarSizeXl = 96.0;

  /// Canonical composite input-field height — phone auth row.
  static const double inputFieldHeight = 56.0;

  /// Request-summary skeleton card height (submit_bid).
  static const double skeletonCardHeight = 80.0;

  /// SliverAppBar.expandedHeight for the job-detail hero.
  static const double heroExpandedHeight = 220.0;

  /// Avatar image-picker constraints (edit_profile).
  static const double avatarMaxDimensionPx = 512.0;
  static const int    avatarImageQuality   = 85;

  // ── Splash screen ─────────────────────────────────────────────────────────
  /// Fixed height of the status slot below the wordmark. Sized to the error
  /// state (its tallest content: 20 icon + 8 + title + 4 + 2-line message +
  /// 16 + 48 button ≈ 148) so the wordmark never reflows between states.
  static const double splashStatusAreaHeight    = 148.0;
  static const double splashRetryButtonMinWidth = 132.0;

  // ── Opacity tokens — state-conditional destructive tiles ─────────────────
  static const double opacityDisabledColor        = 0.40;
  static const double opacityChevron              = 0.50;
  static const double opacityTileFillDisabled     = 0.04;
  static const double opacityTileFillDarkEn       = 0.12;
  static const double opacityTileFillLightEn      = 0.08;
  static const double opacityDeleteTileFillDarkEn = 0.08;
  static const double opacityDeleteFillLightEn    = 0.05;
  static const double opacityDeleteFillDis        = 0.03;
  static const double opacityIconBg               = 0.12;
  static const double opacityIconBgAlt            = 0.15;
  static const double opacityBorderEnabled        = 0.20;
  static const double opacityBorderDisabled       = 0.08;
  static const double opacityDeleteBorderDis      = 0.06;

  // ── Opacity tokens — SheetOption ─────────────────────────────────────────
  static const double opacitySheetFillDark    = 0.20;
  static const double opacitySheetFillLight   = 0.10;
  static const double opacitySheetBorderSel   = 0.50;
  static const double opacitySheetBorderUnsel = 0.20;
  static const double opacitySheetIconMuted   = 0.60;

  // Location & map
  static const double defaultSearchRadiusKm = 50.0;
  static const double minSearchRadiusKm     = 5.0;
  static const double maxSearchRadiusKm     = 100.0;
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const double defaultZoom = 12.0;
  static const double minZoom     = 8.0;
  static const double maxZoom     = 18.0;

  static const Map<String, LatLng> cityCenters = {
    'alger':       LatLng(36.7372, 3.0865),
    'oran':        LatLng(35.7089, -0.6416),
    'constantine': LatLng(36.3650, 6.6147),
    'annaba':      LatLng(36.9000, 7.7667),
    'blida':       LatLng(36.4203, 2.8277),
    'batna':       LatLng(35.5559, 6.1741),
    'djelfa':      LatLng(34.6792, 3.2550),
    'setif':       LatLng(36.1905, 5.4033),
  };

  // File upload
  static const int maxImageSizeMB = 10;
  static const int maxVideoSizeMB = 100;
  static const int maxAudioSizeMB = 50;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 2;
  static const int maxUsernameLength = 50;

  // Input-length tokens.
  /// National phone number digit count (Algeria) — phone_auth.
  static const int phoneNumberLength = 9;
  /// OTP code length — phone_auth.
  static const int otpLength = 6;
  /// Rating comment max length — rating_screen.
  static const int maxRatingCommentLength = 400;
  /// Bid message max length — submit_bid_screen.
  static const int maxBidMessageLength = 300;

  // ── Semantic text style tokens ────────────────────────────────────────────
  // Pre-baked styles — use instead of per-rebuild copyWith() allocations.
  //
  // Pre-baked variants assume the base TextStyle from M3 ThemeData:
  //   • titleSmall (14sp, w500) + w700 bold = titleCardSmall
  //   • bodySmall (12sp, w400) + opacity/color dim = bodyMuted

  /// Card title (14sp, w700) — titleSmall + bold. Used in:
  ///   • CardContainer headers
  ///   • BidCard, JobCard, RequestCard titles
  ///   • About/Help FAQ item titles
  /// Pre-baked to avoid copyWith() on every build.
  static const TextStyle titleCardSmall = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// Secondary body text (12sp, w400, slightly dimmed) — bodySmall with
  /// reduced opacity. Used for subtitle, description text in cards.
  /// Factory method in AppTheme.bodyMuted(isDark) applies the color.
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Small label text (11sp, w600, uppercased) — used for field labels,
  /// section headers, badge text. Pre-baked to avoid copyWith().
  static const TextStyle labelSmallBold = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
}

class AppIcons {
  AppIcons._();

  // Navigation
  static const IconData home             = Icons.home_rounded;
  static const IconData homeOutlined     = Icons.home_outlined;
  static const IconData search           = Icons.search_rounded;
  static const IconData searchOutlined   = Icons.search_outlined;
  static const IconData requests         = Icons.request_page_rounded;
  static const IconData requestsOutlined = Icons.request_page_outlined;
  static const IconData messages         = Icons.message_rounded;
  static const IconData messagesOutlined = Icons.message_outlined;
  static const IconData profile          = Icons.person_rounded;
  static const IconData profileOutlined  = Icons.person_outline_rounded;

  // Worker navigation
  static const IconData dashboard         = Icons.dashboard_rounded;
  static const IconData dashboardOutlined = Icons.dashboard_outlined;
  static const IconData jobs              = Icons.work_rounded;
  static const IconData jobsOutlined      = Icons.work_outline_rounded;

  // Auth
  static const IconData email         = Icons.email_outlined;
  static const IconData password      = Icons.lock_outline_rounded;
  static const IconData visibility    = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData person        = Icons.person_outline_rounded;
  static const IconData phone         = Icons.phone_outlined;

  // Services
  static const IconData plumbing        = Icons.plumbing_rounded;
  static const IconData electrical      = Icons.electrical_services_rounded;
  static const IconData cleaning        = Icons.cleaning_services_rounded;
  static const IconData painting        = Icons.format_paint_rounded;
  static const IconData carpentry       = Icons.carpenter_rounded;
  static const IconData gardening       = Icons.grass_rounded;
  static const IconData airConditioning = Icons.air_rounded;
  static const IconData appliances      = Icons.kitchen_rounded;

  // Actions
  static const IconData add      = Icons.add_rounded;
  static const IconData edit     = Icons.edit_rounded;
  static const IconData delete   = Icons.delete_outline_rounded;
  static const IconData save     = Icons.save_rounded;
  static const IconData cancel   = Icons.cancel_outlined;
  static const IconData check    = Icons.check_circle_rounded;
  static const IconData close    = Icons.close_rounded;
  static const IconData back     = Icons.arrow_back_rounded;
  static const IconData forward  = Icons.arrow_forward_rounded;
  static const IconData upload   = Icons.upload_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData share    = Icons.share_rounded;
  static const IconData filter   = Icons.filter_list_rounded;
  static const IconData sort     = Icons.sort_rounded;
  static const IconData stop     = Icons.stop_rounded;
  static const IconData build    = Icons.build_rounded;
  static const IconData gridView = Icons.grid_view_rounded;

  // Status
  static const IconData pending    = Icons.pending_outlined;
  static const IconData accepted   = Icons.check_circle_outline_rounded;
  static const IconData declined   = Icons.cancel_outlined;
  static const IconData completed  = Icons.done_all_rounded;
  static const IconData inProgress = Icons.hourglass_empty_rounded;

  // Bid model
  static const IconData bid            = Icons.local_offer_rounded;
  static const IconData bidOutlined    = Icons.local_offer_outlined;
  static const IconData tracking       = Icons.track_changes_rounded;
  static const IconData ratingFilled   = Icons.star_rounded;
  static const IconData ratingOutlined = Icons.star_outline_rounded;
  static const IconData timer          = Icons.timer_outlined;
  static const IconData timerActive    = Icons.timer_rounded;
  static const IconData wallet         = Icons.account_balance_wallet_outlined;

  // Settings
  static const IconData settings            = Icons.settings_rounded;
  static const IconData language            = Icons.language_rounded;
  static const IconData theme               = Icons.brightness_6_rounded;
  static const IconData notifications       = Icons.notifications_outlined;
  static const IconData notificationsActive = Icons.notifications_active_rounded;
  static const IconData help                = Icons.help_outline_rounded;
  static const IconData info                = Icons.info_outline_rounded;
  static const IconData logout              = Icons.logout_rounded;
  static const IconData deleteAccount       = Icons.no_accounts_outlined;

  // Map
  static const IconData location         = Icons.location_on_rounded;
  static const IconData locationOutlined = Icons.location_on_outlined;
  static const IconData myLocation       = Icons.my_location_rounded;
  static const IconData directions       = Icons.directions_rounded;
  static const IconData map              = Icons.map_outlined;
  static const IconData openWith         = Icons.open_with_rounded;
  static const IconData locationSearch   = Icons.location_searching_rounded;
  static const IconData locationOff      = Icons.location_off_rounded;

  // Feedback
  static const IconData error   = Icons.error_outline_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData success = Icons.check_circle_outline_rounded;

  // Chat / media
  static const IconData send     = Icons.send_rounded;
  static const IconData attach   = Icons.attach_file_rounded;
  static const IconData image    = Icons.image_outlined;
  static const IconData camera   = Icons.camera_alt_outlined;
  static const IconData mic      = Icons.mic_rounded;
  static const IconData micOff   = Icons.mic_off_rounded;
  static const IconData gallery  = Icons.photo_library_rounded;
  static const IconData videocam = Icons.videocam_rounded;
  static const IconData play     = Icons.play_arrow_rounded;
  static const IconData pause    = Icons.pause_rounded;

  // Rating
  static const IconData star         = Icons.star_rounded;
  static const IconData starOutlined = Icons.star_outline_rounded;
  static const IconData starHalf     = Icons.star_half_rounded;

  // AI
  static const IconData ai         = Icons.auto_awesome_rounded;
  static const IconData aiOutlined = Icons.auto_awesome_outlined;

  // Form / step
  static const IconData editNote      = Icons.edit_note_rounded;
  static const IconData twilight      = Icons.wb_twilight_rounded;
  static const IconData calendarToday = Icons.calendar_today_rounded;

  // ── Screen icons ──────────────────────────────────────────────────────────
  static const IconData privacy          = Icons.privacy_tip_outlined;
  static const IconData terms            = Icons.gavel_rounded;
  static const IconData code             = Icons.code_rounded;
  static const IconData openInNew        = Icons.open_in_new_rounded;
  static const IconData homeRepair       = Icons.home_repair_service_rounded;
  static const IconData notificationsOff = Icons.notifications_off_outlined;
  static const IconData refresh          = Icons.refresh_rounded;
  static const IconData description      = Icons.description_outlined;
  static const IconData media            = Icons.perm_media_rounded;
  static const IconData payments         = Icons.payments_rounded;
  static const IconData timeline         = Icons.timeline_rounded;
  static const IconData bolt             = Icons.bolt_rounded;
  static const IconData verifiedUser     = Icons.verified_user_rounded;
  static const IconData cameraRounded    = Icons.camera_alt_rounded;
  static const IconData remove           = Icons.remove_rounded;
  static const IconData arrowDown        = Icons.keyboard_arrow_down_rounded;
}

class AppRoutes {
  AppRoutes._();

  static const String splash            = '/';
  static const String home              = '/home';
  static const String search            = '/search';
  static const String requests          = '/requests';
  static const String profile           = '/profile';
  static const String workerJobs        = '/worker-jobs';
  static const String workerSettings    = '/worker-settings';
  static const String serviceRequest    = '/service-request';
  static const String workerProfile     = '/worker/:id';
  static const String settings          = '/settings';
  static const String editProfile       = '/edit-profile';
  static const String subscription      = '/subscription';
  static const String notifications     = '/notifications';        // settings/prefs
  static const String notificationsInbox = '/notifications/inbox';  // received inbox
  static const String help              = '/help';
  static const String about             = '/about';
  static const String bidsListScreen    = '/service-request/:id/bids';
  static const String requestTracking   = '/service-request/:id/tracking';
  static const String clientRating      = '/service-request/:id/rating';
  static const String submitBid         = '/worker/jobs/:id/bid';
  static const String workerJobDetail   = '/worker/jobs/:id';

  // ── Phone-auth flow ────────────────────────────────────────────────────────

  /// First-launch onboarding slides (3 screens).
  static const String onboarding         = '/onboarding';

  /// Account-PIN verification (unknown device on a PIN-protected account).
  static const String pinVerify          = '/pin-verify';

  /// Document-approval gate (worker/business docs awaiting admin review).
  static const String pendingApproval    = '/pending-approval';

  /// Account-PIN management (set/change/remove) from settings.
  static const String accountPin         = '/account-pin';

  /// Phone number entry + OTP verification.
  static const String phoneAuth          = '/phone-auth';

  /// Role picker shown to new users after successful phone auth.
  static const String roleSelection      = '/role-selection';

  /// Client profile setup (name + avatar).
  static const String userProfileSetup   = '/user-profile-setup';

  /// Worker profile setup (name + avatar + profession).
  static const String workerProfileSetup = '/worker-profile-setup';

  // Used only in app_router.dart redirect logic (not a registered route):
  static const String workerHome = '/worker-home';
}

class PrefKeys {
  PrefKeys._();

  static const String languageCode  = 'language_code';
  static const String themeMode     = 'theme_mode';
  static const String userId        = 'user_id';
  static const String userType      = 'user_type';
  static const String viewMode      = 'view_mode';
  static const String accountRole   = 'account_role';

  // Per-type notification toggles (Settings → Notifications). Read by both
  // NotificationPrefsNotifier and PushNotificationCoordinator.
  static const String notifNewRequests  = 'notif_new_requests';
  static const String notifBidReceived  = 'notif_bid_received';
  static const String notifChatMessages = 'notif_chat_messages';
  static const String notifPromotions   = 'notif_promotions';
  static const String fcmToken      = 'fcm_token';
  static const String lastLocation  = 'last_location';

  /// Persisted by OnboardingController when user taps "Get started".
  /// Read by the router on every redirect to gate /onboarding display.
  static const String onboardingDone = 'onboarding_done';
}

class UserType {
  UserType._();
  static const String user   = 'user';
  static const String worker = 'worker';
}

class ServiceType {
  ServiceType._();
  static const String plumbing        = 'plumber';
  static const String electrical      = 'electrician';
  static const String cleaning        = 'cleaner';
  static const String painting        = 'painter';
  static const String carpentry       = 'carpenter';
  static const String gardening       = 'gardener';
  static const String airConditioning = 'ac_repair';
  static const String appliances      = 'appliance_repair';
  static const String masonry         = 'mason';

  static List<String> get all => [
    plumbing, electrical, cleaning, painting,
    carpentry, gardening, airConditioning, appliances,
  ];
}
