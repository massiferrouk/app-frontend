import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/logement_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique de la recherche de logements (étudiant).
class RechercheViewModel extends BaseViewModel {
  final LogementService _logements;
  final NavigationService _nav;

  RechercheViewModel(
      {LogementService? logementService, NavigationService? navigationService})
      : _logements = logementService ?? locator<LogementService>(),
        _nav = navigationService ?? locator<NavigationService>();

  final villeController = TextEditingController();

  // ─── Filtres ──────────────────────────────────────────────────
  /// Paliers de loyer proposés en chips (null = pas de filtre)
  static const loyersMax = [500.0, 700.0, 900.0];
  double? loyerMax;
  bool meubleUniquement = false;
  LogementType? type;

  // ─── Résultats + pagination ───────────────────────────────────
  List<Logement> resultats = [];
  bool hasNext = false;
  int _page = 0;
  bool _loadingMore = false;
  String? errorMessage;

  /// Nouvelle recherche : repart de la page 0
  Future<void> search() async {
    _page = 0;
    setBusy(true);
    try {
      final result = await _runSearch(0);
      resultats = result.logements;
      hasNext = result.hasNext;
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Page suivante — appelé quand la liste approche du bas
  Future<void> loadMore() async {
    if (!hasNext || _loadingMore) return;
    _loadingMore = true;
    try {
      final result = await _runSearch(_page + 1);
      _page++;
      resultats = [...resultats, ...result.logements];
      hasNext = result.hasNext;
      notifyListeners();
    } on ApiException {
      // silencieux : l'utilisateur peut re-scroller pour réessayer
    } finally {
      _loadingMore = false;
    }
  }

  Future<({List<Logement> logements, bool hasNext})> _runSearch(int page) =>
      _logements.search(
        ville: villeController.text.trim(),
        loyerMax: loyerMax,
        meuble: meubleUniquement ? true : null,
        type: type,
        page: page,
      );

  // ─── Setters de filtres — chaque changement relance la recherche ──

  void setLoyerMax(double? value) {
    loyerMax = (loyerMax == value) ? null : value; // re-tap = désactive
    search();
  }

  void toggleMeuble() {
    meubleUniquement = !meubleUniquement;
    search();
  }

  void setType(LogementType? value) {
    type = (type == value) ? null : value;
    search();
  }

  void goToDetail(Logement logement) {
    _nav.navigateTo(
      Routes.logementDetailView,
      arguments: LogementDetailViewArguments(logement: logement),
    );
  }

  @override
  void dispose() {
    villeController.dispose();
    super.dispose();
  }
}
