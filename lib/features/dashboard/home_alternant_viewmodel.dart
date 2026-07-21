import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/calendrier_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/logement_service.dart';
import '../../services/notification_service.dart';
import '../../shared/models/alternant_dashboard.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';
import '../../shared/models/mes_semaines.dart';

/// Logique du dashboard alternant.
class HomeAlternantViewModel extends BaseViewModel {
  final DashboardService _dashboard;
  final CalendrierService _calendrier;
  final LogementService _logements;
  final NotificationService _notifications;
  final NavigationService _nav;

  HomeAlternantViewModel(
      {DashboardService? dashboardService,
      CalendrierService? calendrierService,
      LogementService? logementService,
      NotificationService? notificationService,
      NavigationService? navigationService})
      : _dashboard = dashboardService ?? locator<DashboardService>(),
        _calendrier = calendrierService ?? locator<CalendrierService>(),
        _logements = logementService ?? locator<LogementService>(),
        _notifications = notificationService ?? locator<NotificationService>(),
        _nav = navigationService ?? locator<NavigationService>();

  AlternantDashboard? dashboard;

  /// Calendrier de l'alternant — alimente la carte « cette semaine » (APP-117).
  /// null si non chargé (erreur réseau) : la carte est alors simplement masquée.
  MesSemaines? semaines;

  /// Logements de l'utilisateur — pour la check-list « premières étapes ».
  List<Logement> logements = const [];

  String? errorMessage;
  int unreadCount = 0;

  void goToCalendrier() => _nav.navigateTo(Routes.monCalendrierView);

  /// Ouvre la gestion des logements (check-list « publie ton logement »),
  /// puis recharge au retour — le statut du logement a pu changer.
  Future<void> goToGererLogements() async {
    await _nav.navigateTo(
      Routes.mesLogementsView,
      arguments: const MesLogementsViewArguments(standalone: true),
    );
    await load();
  }

  /// Ouvre les notifications puis rafraîchit le badge au retour.
  Future<void> goToNotifications() async {
    await _nav.navigateTo(
      Routes.notificationsView,
      arguments: const NotificationsViewArguments(standalone: true),
    );
    await _refreshUnreadCount();
  }

  /// Chargement initial ET pull-to-refresh
  Future<void> load() async {
    setBusy(true);
    try {
      dashboard = await _dashboard.getAlternantDashboard();
      errorMessage = null;
    } on ApiException catch (e) {
      // Le dashboard est essentiel : son échec affiche l'état d'erreur.
      errorMessage = e.message;
      setBusy(false);
      await _refreshUnreadCount();
      return;
    }

    // Enrichissements NON bloquants : l'accueil s'affiche même s'ils échouent.
    try {
      semaines = await _calendrier.getMesSemaines();
    } on ApiException {
      semaines = null; // calendrier indisponible → carte masquée
    }
    try {
      logements = await _logements.getMesLogements();
    } on ApiException {
      logements = const [];
    }

    setBusy(false);
    await _refreshUnreadCount();
  }

  /// Le badge est secondaire : une erreur ici ne doit jamais bloquer le dashboard.
  Future<void> _refreshUnreadCount() async {
    try {
      unreadCount = await _notifications.getUnreadCount();
      notifyListeners();
    } on ApiException {
      // silencieux
    }
  }

  // ─── Carte « cette semaine » (APP-117) ──────────────────────────

  DateTime get _thisMonday {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  AlternanceSemaine? _weekStarting(DateTime monday) {
    for (final s in semaines?.semaines ?? const <AlternanceSemaine>[]) {
      if (s.semaine.year == monday.year &&
          s.semaine.month == monday.month &&
          s.semaine.day == monday.day) {
        return s;
      }
    }
    return null;
  }

  /// La semaine en cours (null si l'alternance n'a pas commencé / est finie).
  AlternanceSemaine? get semaineCourante => _weekStarting(_thisMonday);

  /// La semaine suivante (null si hors période).
  AlternanceSemaine? get semaineProchaine =>
      _weekStarting(_thisMonday.add(const Duration(days: 7)));

  /// La semaine à mettre en avant sur l'accueil : la semaine en cours si on est
  /// dedans, sinon la 1re semaine à venir (alternance pas encore commencée —
  /// fréquent avant la rentrée). null seulement si aucune semaine future.
  AlternanceSemaine? get semaineAAfficher {
    final courante = semaineCourante;
    if (courante != null) return courante;
    final futures = [
      for (final s in semaines?.semaines ?? const <AlternanceSemaine>[])
        if (!s.semaine.isBefore(_thisMonday)) s
    ]..sort((a, b) => a.semaine.compareTo(b.semaine));
    return futures.isEmpty ? null : futures.first;
  }

  /// true si l'alternance a déjà commencé (on est dans une semaine du calendrier).
  bool get alternanceCommencee => semaineCourante != null;

  /// Ville d'une semaine (école pour le label 'A', entreprise pour 'B').
  String villeDe(AlternanceSemaine s) => semaines?.villeFor(s.label) ?? '';

  /// true si la semaine est une semaine école (label 'A'), sinon entreprise.
  bool estEcole(AlternanceSemaine s) => s.label == 'A';

  // ─── Check-list « premières étapes » (APP-117) ──────────────────

  /// Compte « neuf » : aucun match compatible → on guide l'utilisateur
  /// avec la check-list plutôt que de lui montrer une carte vide.
  bool get isNouveau =>
      dashboard != null && dashboard!.nbMatchesCompatibles == 0;

  /// A-t-il au moins un logement publié (ACTIF) ?
  bool get hasPublishedLogement =>
      logements.any((l) => l.statut == LogementStatut.ACTIF);
}
