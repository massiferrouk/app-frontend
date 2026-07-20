import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/accord_service.dart';
import '../../services/logement_service.dart';
import '../../services/notification_service.dart';
import '../../shared/models/accord.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique du dashboard étudiant : logements en vedette + accords en cours.
class HomeEtudiantViewModel extends BaseViewModel {
  final LogementService _logements;
  final AccordService _accords;
  final NotificationService _notifications;
  final NavigationService _nav;

  HomeEtudiantViewModel({
    LogementService? logementService,
    AccordService? accordService,
    NotificationService? notificationService,
    NavigationService? navigationService,
  })  : _logements = logementService ?? locator<LogementService>(),
        _accords = accordService ?? locator<AccordService>(),
        _notifications = notificationService ?? locator<NotificationService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<Logement> vedettes = [];
  List<Accord> accordsEnCours = [];
  String? errorMessage;
  int unreadCount = 0;

  /// Compte « neuf/inactif » : aucun accord en cours → on affiche le bloc
  /// « Bien démarrer » pour guider l'étudiant plutôt que de laisser du vide
  /// (APP-117 — équivalent des « premières étapes » de l'accueil alternant).
  bool get isNouveau => accordsEnCours.isEmpty;

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
