import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/logement_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique de l'écran "Mes logements".
class MesLogementsViewModel extends BaseViewModel {
  final LogementService _logements;
  final ProfileService _profile;
  final NavigationService _nav;

  MesLogementsViewModel(
      {LogementService? logementService,
      ProfileService? profileService,
      NavigationService? navigationService})
      : _logements = logementService ?? locator<LogementService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _nav = navigationService ?? locator<NavigationService>();

  /// Ouvre le formulaire d'ajout, puis recharge la liste au retour
  /// si un logement a été créé.
  Future<void> goToAjouter() async {
    final created = await _nav.navigateTo(Routes.ajouterLogementView);
    if (created == true) await load();
  }

  /// Ouvre le formulaire pré-rempli pour modifier un logement, puis recharge.
  Future<void> goToModifier(Logement logement) async {
    final updated = await _nav.navigateTo(
      Routes.ajouterLogementView,
      arguments: AjouterLogementViewArguments(logement: logement),
    );
    if (updated == true) await load();
  }

  /// Ouvre le détail d'un logement (données passées en argument)
  void goToDetail(Logement logement) {
    _nav.navigateTo(
      Routes.logementDetailView,
      arguments: LogementDetailViewArguments(logement: logement),
    );
  }

  List<Logement> logements = [];
  String? errorMessage;

  /// L'association VILLE_A/VILLE_B n'a de sens que pour un alternant
  bool isAlternant = false;

  /// Noms réels des villes du profil, pour un affichage explicite lors de
  /// l'association (« Paris (ville de ton école) » plutôt que « Ville A »).
  String? villeEcole; // villeA
  String? villeEntreprise; // villeB

  Future<void> load() async {
    setBusy(true);
    try {
      isAlternant = await _profile.currentRole() == UserRole.ALTERNANT;
      if (isAlternant) {
        final profil = await _profile.getMyAlternantProfile();
        villeEcole = profil?.villeA;
        villeEntreprise = profil?.villeB;
      }
      logements = await _logements.getMesLogements();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Publie un brouillon. Retourne null si OK, message d'erreur sinon.
  Future<String?> publish(Logement logement) async {
    try {
      await _logements.publish(logement.id);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Supprime un logement m'appartenant (brouillon ou publié).
  /// Retourne null si OK, un message d'erreur sinon (409 = accord lié).
  Future<String?> supprimer(Logement logement) async {
    try {
      await _logements.delete(logement.id);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.isConflict
          ? 'Ce logement est lié à un accord et ne peut pas être supprimé'
          : e.message;
    }
  }

  /// Associe un logement à une ville du profil.
  /// Le 409 (ville déjà occupée) remonte avec le message backend.
  Future<String?> associer(Logement logement, VilleAssociee ville) async {
    try {
      await _logements.associerVille(logement.id, ville);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.isConflict
          ? 'Tu as déjà un logement associé à cette ville'
          : e.message;
    }
  }
}
