import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../services/auth_service.dart';

/// ViewModel de l'écran de démarrage.
/// Décide de la première destination : Home si une session existe,
/// Login sinon.
class StartupViewModel extends BaseViewModel {
  final AuthService _auth;
  final NavigationService _nav;

  StartupViewModel(
      {AuthService? authService, NavigationService? navigationService})
      : _auth = authService ?? locator<AuthService>(),
        _nav = navigationService ?? locator<NavigationService>();

  Future<void> runStartupLogic() async {
    // Courte pause : laisse le logo visible au lieu d'un flash désagréable
    await Future.delayed(const Duration(milliseconds: 800));

    final loggedIn = await _auth.isLoggedIn();

    // clearStackAndShow : le splash ne doit jamais être accessible
    // via le bouton retour
    if (loggedIn) {
      await _nav.clearStackAndShow(Routes.homeView);
    } else {
      await _nav.clearStackAndShow(Routes.loginView);
    }
  }
}
