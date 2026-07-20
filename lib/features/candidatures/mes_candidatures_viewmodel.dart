import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/candidature_service.dart';
import '../../shared/models/candidature.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique de « Mes candidatures » (APP-117) — le suivi des annonces auxquelles
/// l'utilisateur a postulé. Les statuts sont modifiés à la main.
class MesCandidaturesViewModel extends BaseViewModel {
  final CandidatureService _candidatures;
  final NavigationService _nav;

  MesCandidaturesViewModel({
    CandidatureService? candidatureService,
    NavigationService? navigationService,
  })  : _candidatures = candidatureService ?? locator<CandidatureService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<Candidature> _all = [];
  String? errorMessage;

  /// Filtre actif — null = tout afficher
  CandidatureStatut? filtre;

  Future<void> load() async {
    setBusy(true);
    try {
      _all = await _candidatures.getMesCandidatures();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Les candidatures visibles selon le filtre actif
  List<Candidature> get candidatures =>
      filtre == null ? _all : _all.where((c) => c.statut == filtre).toList();

  /// true s'il n'y a aucune candidature du tout (≠ « aucune dans ce filtre »)
  bool get isEmpty => _all.isEmpty;

  /// Nombre par statut — alimente les compteurs des filtres
  int countFor(CandidatureStatut statut) =>
      _all.where((c) => c.statut == statut).length;

  /// Re-tap sur un filtre actif = on l'enlève
  void toggleFiltre(CandidatureStatut statut) {
    filtre = filtre == statut ? null : statut;
    notifyListeners();
  }

  /// Change le statut d'une candidature. Retourne null si OK, le message sinon.
  Future<String?> changerStatut(
      Candidature candidature, CandidatureStatut statut) async {
    try {
      final maj = await _candidatures.updateStatut(
        candidatureId: candidature.id,
        statut: statut,
        note: candidature.note,
      );
      // Remplace l'élément sur place : pas besoin de recharger toute la liste
      _all = [
        for (final c in _all) if (c.id == maj.id) maj else c,
      ];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Retire une annonce du suivi.
  Future<String?> retirer(Candidature candidature) async {
    try {
      await _candidatures.delete(candidature.id);
      _all = _all.where((c) => c.id != candidature.id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void goToDetail(Logement logement) => _nav.navigateTo(
        Routes.logementDetailView,
        arguments: LogementDetailViewArguments(logement: logement),
      );
}
