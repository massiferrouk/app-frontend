import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/candidature_service.dart';
import '../../services/logement_service.dart';
import '../../services/matching_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique de la recherche de logements (étudiant).
class RechercheViewModel extends BaseViewModel {
  final LogementService _logements;
  final MatchingService _matching;
  final ProfileService _profile;
  final CandidatureService _candidatures;
  final NavigationService _nav;

  RechercheViewModel(
      {LogementService? logementService,
      MatchingService? matchingService,
      ProfileService? profileService,
      CandidatureService? candidatureService,
      NavigationService? navigationService})
      : _logements = logementService ?? locator<LogementService>(),
        _matching = matchingService ?? locator<MatchingService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _candidatures = candidatureService ?? locator<CandidatureService>(),
        _nav = navigationService ?? locator<NavigationService>();

  /// Statut de suivi par annonce (APP-119) : permet d'afficher « Contacté »,
  /// « Visité »… directement sur les cartes de résultats, pour reconnaître
  /// une annonce déjà traitée sans l'ouvrir.
  /// Une annonce absente de cette map n'est pas suivie → aucun badge.
  Map<String, CandidatureStatut> statutsSuivis = {};

  CandidatureStatut? statutPour(String logementId) => statutsSuivis[logementId];

  /// Recharge les candidatures pour alimenter les badges.
  /// Silencieux : un échec ne doit pas casser la recherche, les cartes
  /// s'affichent simplement sans badge.
  Future<void> _refreshStatutsSuivis() async {
    try {
      final mes = await _candidatures.getMesCandidatures();
      statutsSuivis = {for (final c in mes) c.logement.id: c.statut};
      notifyListeners();
    } on ApiException {
      // non bloquant
    }
  }

  final villeController = TextEditingController();

  // ─── Filtres ──────────────────────────────────────────────────
  /// Paliers de loyer proposés en chips (null = pas de filtre)
  static const loyersMax = [500.0, 700.0, 900.0];
  double? loyerMax;
  bool meubleUniquement = false;
  LogementType? type;

  // ─── Tri (APP-117) ────────────────────────────────────────────
  // Le backend supportait déjà tri=prix_asc|prix_desc|surface_desc, mais le
  // front ne l'exposait pas. C'est ce qui distingue vraiment la Recherche de
  // l'aperçu de l'accueil. 'pertinence' tombe sur le tri par défaut du back.
  static const trisDisponibles = {
    'pertinence': 'Pertinence',
    'prix_asc': 'Prix croissant',
    'prix_desc': 'Prix décroissant',
    'surface_desc': 'Surface',
  };
  String tri = 'pertinence';

  String get triLabel => trisDisponibles[tri] ?? 'Pertinence';

  // ─── Résultats + pagination ───────────────────────────────────
  List<Logement> resultats = [];
  bool hasNext = false;

  /// Nombre TOTAL de résultats (toutes pages) — pour l'en-tête « X logements ».
  int totalResultats = 0;
  int _page = 0;
  bool _loadingMore = false;
  String? errorMessage;

  // ─── Carte matching dans les résultats (APP-104) ──────────────
  /// Alternants compatibles dont une des villes est la ville recherchée.
  /// 0 = pas de carte affichée (étudiant, ville vide, aucun match...).
  int matchsCompatibles = 0;

  /// Meilleure économie mensuelle parmi ces matchs (0 = pas de chiffre)
  int economieMaxMatchs = 0;

  /// Ville affichée dans la carte (figée au moment de la recherche)
  String villeMatchs = '';

  /// Nouvelle recherche : repart de la page 0
  Future<void> search() async {
    _page = 0;
    setBusy(true);
    try {
      final result = await _runSearch(0);
      resultats = result.logements;
      hasNext = result.hasNext;
      totalResultats = result.total;
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
    // Les badges de suivi sont rafraîchis à chaque recherche : le statut a pu
    // changer depuis l'écran Candidatures entre-temps.
    await _refreshStatutsSuivis();
    await _refreshMatchingCard();
  }

  /// La carte matching est un bonus : toute erreur ici est silencieuse.
  /// Réservée aux alternants — le matching ne concerne pas les étudiants.
  Future<void> _refreshMatchingCard() async {
    matchsCompatibles = 0;
    economieMaxMatchs = 0;
    villeMatchs = villeController.text.trim();
    if (villeMatchs.isEmpty) {
      notifyListeners();
      return;
    }
    try {
      if (await _profile.currentRole() != UserRole.ALTERNANT) {
        notifyListeners();
        return;
      }
      final suggestions = await _matching.getSuggestions();
      final dansVille = suggestions
          .where((s) =>
              s.villeA.toLowerCase() == villeMatchs.toLowerCase() ||
              s.villeB.toLowerCase() == villeMatchs.toLowerCase())
          .toList();
      matchsCompatibles = dansVille.length;
      economieMaxMatchs = dansVille.fold(
          0, (max, s) => s.economieMensuelle > max ? s.economieMensuelle : max);
    } on ApiException {
      // silencieux — pas de profil alternant, réseau...
    }
    notifyListeners();
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

  Future<({List<Logement> logements, bool hasNext, int total})> _runSearch(
          int page) =>
      _logements.search(
        ville: villeController.text.trim(),
        loyerMax: loyerMax,
        meuble: meubleUniquement ? true : null,
        type: type,
        tri: tri,
        page: page,
      );

  /// Libellé de l'en-tête de résultats : « 12 logements » / « 12 logements à Paris ».
  String get resultatsLabel {
    if (totalResultats == 0) return '';
    final mot = totalResultats > 1 ? 'logements' : 'logement';
    final ville = villeController.text.trim();
    return ville.isEmpty
        ? '$totalResultats $mot'
        : '$totalResultats $mot à $ville';
  }

  /// true si au moins un critère est actif → on propose « Réinitialiser ».
  bool get hasFiltresActifs =>
      loyerMax != null ||
      meubleUniquement ||
      type != null ||
      tri != 'pertinence' ||
      villeController.text.trim().isNotEmpty;

  /// Remet la recherche à zéro (tous critères + tri) et relance.
  void resetFiltres() {
    villeController.clear();
    loyerMax = null;
    meubleUniquement = false;
    type = null;
    tri = 'pertinence';
    search();
  }

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

  void setTri(String value) {
    tri = value;
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
