import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../services/onboarding_service.dart';

/// Logique de l'onboarding du premier lancement (APP-105).
/// 3 écrans swipables ; « Passer » et « C'est parti » mènent au login
/// et marquent l'onboarding comme vu (plus jamais réaffiché).
class OnboardingViewModel extends BaseViewModel {
  final OnboardingService _onboarding;
  final NavigationService _nav;

  OnboardingViewModel(
      {OnboardingService? onboardingService,
      NavigationService? navigationService})
      : _onboarding = onboardingService ?? locator<OnboardingService>(),
        _nav = navigationService ?? locator<NavigationService>();

  static const nbPages = 3;

  final pageController = PageController();
  int pageCourante = 0;

  bool get dernierePage => pageCourante == nbPages - 1;

  void onPageChanged(int index) {
    pageCourante = index;
    notifyListeners();
  }

  /// Bouton principal : page suivante, ou fin sur la dernière page
  Future<void> suivant() async {
    if (dernierePage) return terminer();
    pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  /// « Passer » ou « C'est parti » : marque vu + va au login.
  /// clearStackAndShow : pas de retour possible vers l'onboarding.
  Future<void> terminer() async {
    await _onboarding.marquerVu();
    await _nav.clearStackAndShow(Routes.loginView);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
