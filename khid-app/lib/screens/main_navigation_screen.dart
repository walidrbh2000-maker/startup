// lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/home_controller.dart';
import '../providers/user_role_provider.dart';
import '../utils/system_ui_overlay.dart';
import '../widgets/app_navigation_bars.dart';
import '../widgets/location_permission_overlay.dart';

// Shell branch indices (see app_router.dart): 0 home, 1 worker jobs, 2 settings.
// Tab position n maps to branch _clientBranches/_workerBranches[n].
const List<int> _clientBranches = [0, 2];
const List<int> _workerBranches = [0, 1, 2];

class MainNavigationScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainNavigationScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedRole    = ref.watch(cachedUserRoleProvider);
    final isWorker      = cachedRole == UserRole.worker;
    // Guests never resolve a role (anonymous uid has no profile) — they
    // browse with the client bar instead of getting no bar at all.
    final isGuest       = ref.watch(isGuestProvider);
    final roleResolved  = cachedRole != UserRole.unknown || isGuest;
    final branches      = isWorker ? _workerBranches : _clientBranches;
    final tabIndex      = branches.indexOf(navigationShell.currentIndex);
    final selectedIndex = tabIndex < 0 ? 0 : tabIndex;

    final isMapFullscreen = ref.watch(
      homeControllerProvider.select((s) => s.isMapFullscreen),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Re-apply edge-to-edge on every rebuild so no branch can flash the
    // system nav bar back to a solid colour.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(systemOverlayStyle(isDark));

    // Bar hidden until the cached role resolves — rendering the 2-tab client
    // bar first then swapping to 3 tabs is a visible flash. If the role never
    // resolves (network failure) home stays usable without a bottom nav.
    final Widget? bottomNav = (isMapFullscreen || !roleResolved)
        ? null
        : (isWorker
            ? WorkerNavigationBar(
                currentIndex: selectedIndex,
                onTap:        (i) => navigationShell.goBranch(branches[i]),
              )
            : UserNavigationBar(
                currentIndex: selectedIndex,
                onTap:        (i) => navigationShell.goBranch(branches[i]),
              ));

    // System back on a secondary tab returns to the home tab first (Android
    // bottom-nav convention); only home lets the pop exit the app. go_router
    // handles pushed routes above the shell before this PopScope is reached.
    final onHomeBranch = navigationShell.currentIndex == 0;

    return PopScope(
      canPop: onHomeBranch,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        extendBody:             true,
        extendBodyBehindAppBar: true,
        body: LocationPermissionGate(child: navigationShell),
        bottomNavigationBar: bottomNav,
      ),
    );
  }
}
