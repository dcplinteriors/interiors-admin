import 'package:dcpl_admin/core/core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// App shell hosting the three branches. `navigationShell` is the IndexedStack of
/// branches (state preserved); the adaptive nav drives it via `currentIndex` /
/// `goBranch`. The nav is a rail on tablet/desktop and a bottom bar on phones —
/// see [AdaptiveNavScaffold].
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = Get.find<AuthService>();

    return AdaptiveNavScaffold(
      title: l10n.appTitle,
      actions: [
        // Email is space-hungry; show it only where there's room (tablet+).
        if (!context.isCompact)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text(auth.currentUser?.email ?? '')),
          ),
        IconButton(
          tooltip: l10n.signOut,
          // Sign out flips the auth state; the router's redirect sends us to /login.
          onPressed: auth.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        // Re-tapping the current tab pops it back to that branch's root.
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: [
        AdaptiveDestination(
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          label: l10n.navProjects,
        ),
        AdaptiveDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: l10n.navSupervisors,
        ),
        AdaptiveDestination(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: l10n.navRequests,
        ),
      ],
      body: navigationShell,
    );
  }
}
