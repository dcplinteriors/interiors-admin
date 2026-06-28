import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/material_requests/material_requests.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// App shell hosting the four branches (Projects · Work Orders · Supervisors · Requests).
/// `navigationShell` is the IndexedStack of branches (state preserved); the Molten
/// [DcplNavScaffold] drives it via `currentIndex` / `goBranch` — a labeled rail on
/// tablet/desktop, a floating bottom bar on phones.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    // The shell mounts once the user is signed in — load the pending-requests badge now.
    Get.find<RequestsBadgeController>().refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = Get.find<AuthService>();
    final badge = Get.find<RequestsBadgeController>();

    // Rebuild when the Requests badge changes.
    return Obx(() {
      final items = [
        DcplNavItem(
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          label: l10n.navProjects,
          section: l10n.navSectionWorkspace,
        ),
        DcplNavItem(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: l10n.navWorkOrders,
          section: l10n.navSectionWorkspace,
        ),
        DcplNavItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: l10n.navSupervisors,
          section: l10n.navSectionWorkspace,
        ),
        DcplNavItem(
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront,
          label: l10n.navVendors,
          section: l10n.navSectionWorkspace,
        ),
        DcplNavItem(
          icon: Icons.inbox_outlined,
          selectedIcon: Icons.inbox,
          label: l10n.navRequests,
          section: l10n.navSectionInbox,
          badgeCount: badge.count.value,
        ),
      ];

      return DcplNavScaffold(
        items: items,
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) => widget.navigationShell.goBranch(
          index,
          // Re-tapping the current tab pops it back to that branch's root.
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        railHeader: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: _BrandLockup(stacked: false, logoHeight: 40),
        ),
        railFooter: _AccountRow(
          email: auth.currentUser?.email ?? '',
          signOutLabel: l10n.signOut,
          onSignOut: auth.signOut,
        ),
        appBarTitle: const _BrandLockup(stacked: false, logoHeight: 40),
        appBarActions: [
          IconButton(
            tooltip: l10n.signOut,
            onPressed: auth.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
        body: widget.navigationShell,
      );
    });
  }
}

/// The brand wordmark paired with an "Admin" role tag — distinguishing this from the
/// supervisor app. [stacked] places the tag under the logo (rail), else inline to its
/// right with a hairline separator (mobile app bar).
class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.stacked, required this.logoHeight});

  final bool stacked;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tag = Text(
      'Admin',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: scheme.onSurfaceVariant,
      ),
    );
    final logo = BrandWordmark(height: logoHeight);
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [logo, const SizedBox(height: 5), tag],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: 10),
        Container(width: 1, height: 16, color: scheme.outlineVariant),
        const SizedBox(width: 10),
        tag,
      ],
    );
  }
}

/// The pinned rail footer — the signed-in admin's email and a sign-out affordance.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.email,
    required this.signOutLabel,
    required this.onSignOut,
  });

  final String email;
  final String signOutLabel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: signOutLabel,
      child: InkWell(
        onTap: onSignOut,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(Icons.logout, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
