import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/logement_service.dart';
import '../../shared/models/disponibilite.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/reputation_score.dart';

/// Logique du détail d'un logement.
/// Le logement arrive en argument de navigation ; les disponibilités
/// et la réputation du propriétaire se chargent ensuite.
class LogementDetailViewModel extends BaseViewModel {
  final LogementService _logements;
  final Logement logement;

  LogementDetailViewModel(
      {required this.logement, LogementService? logementService})
      : _logements = logementService ?? locator<LogementService>();

  List<Disponibilite> disponibilites = [];
  ReputationScore? reputation;

  /// Charge les données secondaires. Chacune peut échouer sans bloquer
  /// l'écran : le logement principal est déjà affichable.
  Future<void> loadExtras() async {
    setBusy(true);
    try {
      disponibilites = await _logements.getDisponibilites(logement.id);
    } on ApiException {
      // Non bloquant : la section disponibilités restera vide
    }
    try {
      reputation = await _logements.getReputation(logement.ownerId);
    } on ApiException {
      // Non bloquant : la carte propriétaire s'affiche sans score
    }
    setBusy(false);
  }

  /// Disponibilités des 4 prochaines semaines uniquement
  List<Disponibilite> get prochainesDisponibilites {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 28));
    return disponibilites
        .where((d) =>
            d.dateFin.isAfter(now) && d.dateDebut.isBefore(horizon))
        .toList();
  }
}
