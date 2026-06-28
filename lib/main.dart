import 'dart:async';

import 'package:dcpl_admin/app/app.dart';
import 'package:dcpl_admin/core/core.dart';
import 'package:dcpl_admin/features/features.dart';
import 'package:dcpl_admin/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _registerDependencies();
  runApp(const DcplAdminApp());
}

/// GetX is the DI container + state layer (go_router owns routing). Controllers are
/// created lazily on first use — replaces the old route bindings.
void _registerDependencies() {
  Get.put(AuthService(), permanent: true);
  Get.put(ApiClient(Get.find<AuthService>()), permanent: true);
  // Single typed endpoint layer; every repo delegates to it.
  Get.put(DcplApi(Get.find<ApiClient>()), permanent: true);

  // Wake a scaled-to-zero backend instance during launch so the first data
  // screen doesn't hit a cold start. Fire-and-forget; never throws.
  unawaited(Get.find<ApiClient>().warmUp());

  Get.lazyPut<SupervisorRepository>(() => ApiSupervisorRepository(Get.find()));
  Get.lazyPut<ProjectRepository>(() => ApiProjectRepository(Get.find()));
  Get.lazyPut<WorkOrderRepository>(() => ApiWorkOrderRepository(Get.find()));
  Get.lazyPut<MaterialRequestRepository>(
    () => ApiMaterialRequestRepository(Get.find()),
  );
  Get.lazyPut<VendorRepository>(() => ApiVendorRepository(Get.find()));
  Get.lazyPut<AttachmentRepository>(() => ApiAttachmentRepository(Get.find()));

  // Permanent so the Requests nav badge survives navigation without forcing the requests list to
  // load. HomeShell loads it on mount; the requests controller refreshes it after admin actions.
  Get.put(
    RequestsBadgeController(Get.find<MaterialRequestRepository>()),
    permanent: true,
  );

  Get.lazyPut(() => LoginController(Get.find()), fenix: true);
  Get.lazyPut(
    () => ProjectsController(Get.find<ProjectRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => WorkOrdersController(
      Get.find<WorkOrderRepository>(),
      Get.find<SupervisorRepository>(),
      Get.find<ProjectRepository>(),
    ),
    fenix: true,
  );
  Get.lazyPut(
    () => SupervisorsController(Get.find<SupervisorRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => VendorsController(Get.find<VendorRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => MaterialRequestsController(
      Get.find<MaterialRequestRepository>(),
      Get.find<ProjectRepository>(),
      Get.find<WorkOrderRepository>(),
      Get.find<SupervisorRepository>(),
    ),
    fenix: true,
  );
}

class DcplAdminApp extends StatelessWidget {
  const DcplAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    debugShowCheckedModeBanner: false,
    // Both themes are wired so switching works; the app is locked to dark for
    // now (no UI toggle). Flip to ThemeMode.system/.light to expose light.
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.dark,
    scaffoldMessengerKey: rootScaffoldMessengerKey,
    routerConfig: AppRouter.router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}
