import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/profile_service.dart';

/// ViewModel de l'écran de démarrage.
/// Décide de la première destination : onboarding au premier lancement,
/// Login si pas de session, création de profil si ALTERNANT sans profil,
/// Home sinon.
class StartupViewModel extends BaseViewModel {
  final AuthService _auth;
  final ProfileService _profile;
  final OnboardingService _onboarding;
  final NavigationService _nav;

  StartupViewModel({
    AuthService? authService,
    ProfileService? profileService,
    OnboardingService? onboardingService,
    NavigationService? navigationService,
  })  : _auth = authService ?? locator<AuthService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _onboarding = onboardingService ?? locator<OnboardingService>(),
        _nav = navigationService ?? locator<NavigationService>();

  Future<void> runStartupLogic() async {
    // Courte pause : laisse le logo visible au lieu d'un flash désagréable
    await Future.delayed(const Duration(milliseconds: 800));

    // clearStackAndShow : le splash ne doit jamais être accessible
    // via le bouton retour
    if (!await _auth.isLoggedIn()) {
      // Premier lancement : le concept StudUp d'abord, le login ensuite
      if (!await _onboarding.dejaVu()) {
        await _nav.clearStackAndShow(Routes.onboardingView);
      } else {
        await _nav.clearStackAndShow(Routes.loginView);
      }
    } else if (await _profile.needsAlternantProfile()) {
      // Cas : app fermée après login mais avant la création du profil
      await _nav.clearStackAndShow(Routes.profilCreationView);
    } else {
      await _nav.clearStackAndShow(Routes.mainView);
    }
  }
}
