import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

import '../features/startup/startup_view.dart';

/// Point de vérité unique de l'application.
/// Chaque écran (route) et chaque service (dependency) est déclaré ici,
/// puis build_runner génère app.router.dart et app.locator.dart.
///
/// Commande à relancer après toute modification de ce fichier :
///   dart run build_runner build --delete-conflicting-outputs
@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    // Les prochains écrans seront ajoutés ici (LoginView, RegisterView...)
  ],
  dependencies: [
    // Services Stacked de base — navigation, dialogs, snackbars
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: SnackbarService),
    // Nos services métier seront ajoutés ici (AuthService, MatchingService...)
  ],
)
class App {}
