import 'package:dcpl_admin/app/router/auth_refresh.dart';
import 'package:dcpl_admin/app/routes/app_routes.dart';
import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/features.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.projects,
    refreshListenable: AuthRefresh(Get.find<AuthService>().authStateChanges),
    redirect: (context, state) {
      final loggedIn = Get.find<AuthService>().isLoggedIn;
      final onLogin = state.matchedLocation == AppRoutes.login;
      if (!loggedIn) return onLogin ? null : AppRoutes.login;
      if (onLogin || state.uri.path == '/') return AppRoutes.projects;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginView()),
      // Persistent shell (rail) with each section as a state-preserving branch.
      // The custom container cross-fades branches (instead of the default instant
      // IndexedStack swap) while keeping every branch alive.
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            FadeThroughBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.projects,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: ProjectsView()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workOrders,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: WorkOrdersView()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.supervisors,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: SupervisorsView()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.requests,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: RequestsView()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
