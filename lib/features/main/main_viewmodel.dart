import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../services/profile_service.dart';
import '../../shared/models/enums.dart';

/// ViewModel du shell de navigation.
/// Lit le rôle dans le JWT et pilote l'onglet courant.
class MainViewModel extends BaseViewModel {
  final ProfileService _profile;

  MainViewModel({ProfileService? profileService})
      : _profile = profileService ?? locator<ProfileService>();

  /// Rôle par défaut le temps de lire le token (évite un écran vide)
  UserRole role = UserRole.ALTERNANT;

  int currentIndex = 0;

  Future<void> init() async {
    role = await _profile.currentRole() ?? UserRole.ALTERNANT;
    notifyListeners();
  }

  void setIndex(int index) {
    if (index == currentIndex) return;
    currentIndex = index;
    notifyListeners();
  }
}
