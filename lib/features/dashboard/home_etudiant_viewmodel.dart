import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/accord_service.dart';
import '../../services/logement_service.dart';
import '../../shared/models/accord.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique du dashboard étudiant : logements en vedette + accords en cours.
class HomeEtudiantViewModel extends BaseViewModel {
  final LogementService _logements;
  final AccordService _accords;
  final NavigationService _nav;

  HomeEtudiantViewModel({
    LogementService? logementService,
    AccordService? accordService,
    NavigationService? navigationService,
  })  : _logements = logementService ?? locator<LogementService>(),
        _accords = accordService ?? locator<AccordService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<Logement> vedettes = [];
  List<Accord> accordsEnCours = [];
  String? errorMessage;

  Future<void> load() async {
    setBusy(true);
    try {
      // Les derniers logements publiés, sans filtre (page 0)
      final result = await _logements.search();
      vedettes = result.logements.take(5).toList();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    }

    // Enrichissement non bloquant
    try {
      final accords = await _accords.getMesAccords();
      accordsEnCours = accords
          .where((a) =>
              a.statut == AccordStatut.EN_ATTENTE ||
              a.statut == AccordStatut.ACCEPTE ||
              a.statut == AccordStatut.EN_COURS)
          .toList();
    } on ApiException {/* section vide */}

    setBusy(false);
  }

  void goToDetail(Logement logement) {
    _nav.navigateTo(
      Routes.logementDetailView,
      arguments: LogementDetailViewArguments(logement: logement),
    );
  }
}
