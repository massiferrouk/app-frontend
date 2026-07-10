import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/logement_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique de l'écran "Mes logements".
class MesLogementsViewModel extends BaseViewModel {
  final LogementService _logements;
  final ProfileService _profile;

  MesLogementsViewModel(
      {LogementService? logementService, ProfileService? profileService})
      : _logements = logementService ?? locator<LogementService>(),
        _profile = profileService ?? locator<ProfileService>();

  List<Logement> logements = [];
  String? errorMessage;

  /// L'association VILLE_A/VILLE_B n'a de sens que pour un alternant
  bool isAlternant = false;

  Future<void> load() async {
    setBusy(true);
    try {
      isAlternant = await _profile.currentRole() == UserRole.ALTERNANT;
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
