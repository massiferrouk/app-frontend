import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/dashboard_service.dart';
import '../../services/logement_service.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/proprietaire_dashboard.dart';

/// Logique du dashboard propriétaire.
class HomeProprioViewModel extends BaseViewModel {
  final DashboardService _dashboard;
  final LogementService _logements;

  HomeProprioViewModel({
    DashboardService? dashboardService,
    LogementService? logementService,
  })  : _dashboard = dashboardService ?? locator<DashboardService>(),
        _logements = logementService ?? locator<LogementService>();

  ProprietaireDashboard? dashboard;

  /// Logements complets (avec photos) pour l'aperçu visuel de l'accueil.
  /// Le dashboard ne renvoie que des résumés sans image : on charge donc
  /// la liste complète, comme l'écran « Mes logements », pour afficher de
  /// vraies cartes-annonces au lieu de lignes de texte (même traitement
  /// que l'accueil étudiant).
  List<Logement> logements = [];
  String? errorMessage;

  /// Stale-while-revalidate (APP-122) : l'accueil connu s'affiche tout de suite
  /// et se rafraîchit en fond, plus de spinner à chaque retour sur l'onglet.
  Future<void> load() async {
    // On préaffiche à la fois le dashboard ET la liste des logements depuis le
    // cache (APP-122). Sans la liste, la ré-entrée montrait un bref « Aucun
    // logement » le temps que getMesLogements réponde, alors que le proprio a
    // bien des annonces.
    final cacheDashboard = _dashboard.cachedProprietaireDashboard;
    final cacheLogements = _logements.cachedMesLogements;
    if (cacheDashboard != null || cacheLogements != null) {
      if (cacheDashboard != null) dashboard = cacheDashboard;
      if (cacheLogements != null) logements = cacheLogements;
      notifyListeners();
    } else {
      setBusy(true);
    }
    try {
      dashboard = await _dashboard.getProprietaireDashboard();
      logements = await _logements.getMesLogements();
      errorMessage = null;
    } on ApiException catch (e) {
      if (dashboard == null) errorMessage = e.message;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  /// Alertes dérivées des données : logements en brouillon jamais publiés.
  ///
  /// APP-122 : on ne signale plus « logement actif sans locataire ». Ce n'est
  /// pas une anomalie — c'est l'état normal d'une annonce publiée et disponible
  /// —, donc c'était une fausse alerte sans action possible pour le proprio.
  List<String> get alertes {
    final d = dashboard;
    if (d == null) return [];

    final result = <String>[];
    final brouillons = d.nbLogementsTotaux - d.nbLogementsActifs;
    if (brouillons > 0) {
      result.add(brouillons > 1
          ? '$brouillons logements en brouillon — pense à les publier'
          : '1 logement en brouillon — pense à le publier');
    }
    return result;
  }
}
