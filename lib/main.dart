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

  Get.lazyPut<SupervisorRepository>(() => ApiSupervisorRepository(Get.find()));
  Get.lazyPut<ProjectRepository>(() => ApiProjectRepository(Get.find()));

  Get.lazyPut(() => LoginController(Get.find()), fenix: true);
  Get.lazyPut(
    () => ProjectsController(Get.find<ProjectRepository>(), Get.find<SupervisorRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => SupervisorsController(Get.find<SupervisorRepository>()),
    fenix: true,
  );
  Get.lazyPut<MaterialRequestRepository>(() => ApiMaterialRequestRepository(Get.find()));
  Get.lazyPut<AttachmentRepository>(() => ApiAttachmentRepository(Get.find()));
  Get.lazyPut(
    () => MaterialRequestsController(Get.find<MaterialRequestRepository>()),
    fenix: true,
  );
}

class DcplAdminApp extends StatelessWidget {
  const DcplAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: AppRouter.router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
}
