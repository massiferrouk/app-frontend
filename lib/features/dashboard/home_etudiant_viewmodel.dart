import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/candidature_service.dart';
import '../../services/logement_service.dart';
import '../../services/notification_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique du dashboard étudiant : aperçu des annonces publiées.
class HomeEtudiantViewModel extends BaseViewModel {
  final LogementService _logements;
  final NotificationService _notifications;
  final CandidatureService _candidatures;
  final NavigationService _nav;

  HomeEtudiantViewModel({
    LogementService? logementService,
    NotificationService? notificationService,
    CandidatureService? candidatureService,
    NavigationService? navigationService,
  })  : _logements = logementService ?? locator<LogementService>(),
        _notifications = notificationService ?? locator<NotificationService>(),
        _candidatures = candidatureService ?? locator<CandidatureService>(),
        _nav = navigationService ?? locator<NavigationService>();

  /// Statut de suivi par annonce (APP-119) — même badge que sur la Recherche,
  /// pour que l'utilisateur reconnaisse une annonce déjà traitée partout où
  /// elle apparaît. Absente de la map = non suivie → aucun badge.
  Map<String, CandidatureStatut> statutsSuivis = {};

  CandidatureStatut? statutPour(String logementId) => statutsSuivis[logementId];

  /// Silencieux : un échec n'empêche pas l'accueil de s'afficher.
  Future<void> _refreshStatutsSuivis() async {
    try {
      final mes = await _candidatures.getMesCandidatures();
      statutsSuivis = {for (final c in mes) c.logement.id: c.statut};
      notifyListeners();
    } on ApiException {
      // non bloquant : les cartes s'affichent sans badge
    }
  }

  List<Logement> vedettes = [];
  String? errorMessage;
  int unreadCount = 0;

  /// Compte « neuf/inactif » : aucune annonce suivie → on affiche le bloc
  /// « Bien démarrer » pour guider l'étudiant plutôt que de laisser du vide
  /// (APP-117 — équivalent des « premières étapes » de l'accueil alternant).
  ///
  /// APP-120 : le critère était « aucun accord en cours ». Les accords ayant
  /// été retirés, on prend le signal qui les avait déjà remplacés partout
  /// ailleurs pour l'étudiant — ses candidatures.
  bool get isNouveau => statutsSuivis.isEmpty;

  Future<void> load() async {
    setBusy(true);
    try {
      // Aperçu : seulement les 3 dernières annonces publiées (page 0).
      // La liste complète + filtres + tri, c'est l'écran Recherche (APP-117).
      final result = await _logements.search();
      vedettes = result.logements.take(3).toList();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    }


    setBusy(false);
    await _refreshStatutsSuivis();
    await _refreshUnreadCount();
  }

  void goToDetail(Logement logement) {
    _nav.navigateTo(
      Routes.logementDetailView,
      arguments: LogementDetailViewArguments(logement: logement),
    );
  }

  /// Ouvre les notifications puis rafraîchit le badge au retour
  /// (même pattern que le dashboard alternant, APP-102).
  Future<void> goToNotifications() async {
    await _nav.navigateTo(
      Routes.notificationsView,
      arguments: const NotificationsViewArguments(standalone: true),
    );
    await _refreshUnreadCount();
  }

  /// Le badge est secondaire : une erreur ne doit jamais bloquer le dashboard.
  Future<void> _refreshUnreadCount() async {
    try {
      unreadCount = await _notifications.getUnreadCount();
      notifyListeners();
    } on ApiException {
      // silencieux
    }
  }
}
