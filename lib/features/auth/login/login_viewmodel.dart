import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';

/// Logique de l'écran de connexion — aucun widget ici.
class LoginViewModel extends BaseViewModel {
  final AuthService _auth;
  final ProfileService _profile;
  final NavigationService _nav;

  LoginViewModel({
    AuthService? authService,
    ProfileService? profileService,
    NavigationService? navigationService,
  })  : _auth = authService ?? locator<AuthService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _nav = navigationService ?? locator<NavigationService>();

  // Les controllers vivent dans le ViewModel : la View reste sans état
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// Message d'erreur affiché sous le formulaire (null = pas d'erreur)
  String? errorMessage;

  Future<void> login() async {
    // 1. Validation locale avant tout appel réseau
    errorMessage = Validators.email(emailController.text) ??
        Validators.password(passwordController.text);
    if (errorMessage != null) {
      notifyListeners();
      return;
    }

    // 2. Appel API — setBusy pilote le spinner du bouton
    setBusy(true);
    try {
      await _auth.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      // 3. Succès : un ALTERNANT sans profil passe d'abord par le
      //    formulaire de création, les autres vont à l'accueil.
      //    clearStackAndShow : interdire le retour arrière vers le login.
      if (await _profile.needsAlternantProfile()) {
        await _nav.clearStackAndShow(Routes.profilCreationView);
      } else {
        await _nav.clearStackAndShow(Routes.mainView);
      }
    } on ApiException catch (e) {
      // Le message backend est déjà en français et affichable
      errorMessage = e.isUnauthorized
          ? 'Email ou mot de passe incorrect'
          : e.message;
    } finally {
      setBusy(false); // notifie aussi les listeners
    }
  }

  void goToRegister() => _nav.navigateTo(Routes.registerView);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
