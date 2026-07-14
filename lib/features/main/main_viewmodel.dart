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

  /// Compteurs incrémentés à chaque ouverture de l'onglet Accueil / Messages.
  /// Servent de clé aux vues correspondantes pour forcer un rechargement :
  /// dans un IndexedStack les onglets restent montés, donc sans ça une donnée
  /// arrivée côté serveur (accord reçu, nouveau message) ne s'afficherait
  /// jamais tant que l'utilisateur ne relance pas l'app.
  int homeReloadKey = 0;
  int messagesReloadKey = 0;
  int rechercheReloadKey = 0;

  /// Index de l'onglet Messages selon le rôle (voir _pagesForRole).
  int get _messagesTabIndex =>
      (role == UserRole.PROPRIETAIRE || role == UserRole.ADMIN) ? 2 : 3;

  /// Index de l'onglet Recherche : alternant = 2, étudiant = 1, aucun ailleurs.
  int get _rechercheTabIndex => switch (role) {
        UserRole.ALTERNANT => 2,
        UserRole.ETUDIANT => 1,
        _ => -1,
      };

  Future<void> init() async {
    role = await _profile.currentRole() ?? UserRole.ALTERNANT;
    notifyListeners();
  }

  void setIndex(int index) {
    if (index == currentIndex) return;
    currentIndex = index;
    // Rechargement de la vue à chaque entrée dans l'onglet concerné
    if (index == 0) homeReloadKey++;
    if (index == _messagesTabIndex) messagesReloadKey++;
    if (index == _rechercheTabIndex) rechercheReloadKey++;
    notifyListeners();
  }
}
