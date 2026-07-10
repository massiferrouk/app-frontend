import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

import '../core/api/api_client.dart';
import '../features/auth/login/login_view.dart';
import '../features/auth/profil_creation/profil_creation_view.dart';
import '../features/auth/register/register_view.dart';
import '../features/main/main_view.dart';
import '../features/startup/startup_view.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/profile_service.dart';
import '../services/token_storage_service.dart';

/// Point de vérité unique de l'application.
/// Chaque écran (route) et chaque service (dependency) est déclaré ici,
/// puis build_runner génère app.router.dart et app.locator.dart.
///
/// Commande à relancer après toute modification de ce fichier :
///   dart run build_runner build --delete-conflicting-outputs
@StackedApp(
  routes: [
    MaterialRoute(page: StartupView, initial: true),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: RegisterView),
    MaterialRoute(page: ProfilCreationView),
    MaterialRoute(page: MainView),
    // Les prochains écrans seront ajoutés ici
  ],
  dependencies: [
    // Services Stacked de base — navigation, dialogs, snackbars
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: SnackbarService),
    // Services StudUp
    LazySingleton(classType: TokenStorageService),
    LazySingleton(classType: ApiClient),
    LazySingleton(classType: AuthService),
    LazySingleton(classType: ProfileService),
    LazySingleton(classType: DashboardService),
    // Les services métier seront ajoutés ici (AuthService, MatchingService...)
  ],
)
class App {}
