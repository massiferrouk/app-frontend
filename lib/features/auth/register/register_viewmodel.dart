import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../../../shared/models/enums.dart';

/// Logique de l'écran d'inscription.
class RegisterViewModel extends BaseViewModel {
  final AuthService _auth;
  final NavigationService _nav;

  RegisterViewModel(
      {AuthService? authService, NavigationService? navigationService})
      : _auth = authService ?? locator<AuthService>(),
        _nav = navigationService ?? locator<NavigationService>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// Rôle sélectionné — ADMIN volontairement absent des choix
  UserRole selectedRole = UserRole.ALTERNANT;

  String? errorMessage;

  /// true après inscription réussie : la View bascule sur le message
  /// "email de confirmation envoyé"
  bool emailSent = false;

  void selectRole(UserRole role) {
    selectedRole = role;
    notifyListeners();
  }

  Future<void> register() async {
    // Validation locale, premier message d'erreur trouvé
    errorMessage =
        Validators.requiredField(firstNameController.text, 'Le prénom') ??
            Validators.requiredField(lastNameController.text, 'Le nom') ??
            Validators.email(emailController.text) ??
            Validators.password(passwordController.text);
    if (errorMessage != null) {
      notifyListeners();
      return;
    }

    setBusy(true);
    try {
      await _auth.register(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        role: selectedRole,
      );
      // Pas de tokens ici : le compte attend la confirmation email
      emailSent = true;
    } on ApiException catch (e) {
      errorMessage = e.isConflict
          ? 'Un compte existe déjà avec cet email'
          : e.message;
    } finally {
      setBusy(false);
    }
  }

  void backToLogin() => _nav.back();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
