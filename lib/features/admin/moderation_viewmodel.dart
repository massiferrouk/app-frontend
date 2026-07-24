import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/admin_service.dart';
import '../../services/logement_service.dart';
import '../../shared/models/logement_report.dart';
import '../../shared/models/message_report.dart';

/// Logique de l'écran Modération (APP-121).
class ModerationViewModel extends BaseViewModel {
  final AdminService _admin;
  final LogementService _logements;
  final NavigationService _nav;

  ModerationViewModel(
      {AdminService? adminService,
      LogementService? logementService,
      NavigationService? navigationService})
      : _admin = adminService ?? locator<AdminService>(),
        _logements = logementService ?? locator<LogementService>(),
        _nav = navigationService ?? locator<NavigationService>();

  /// Les mots interdits sont un réglage, consulté rarement : ils n'ont pas
  /// leur place dans la bottom nav, mais bien ici, à côté de la file.
  void ouvrirMotsInterdits() => _nav.navigateTo(Routes.motsInterditsView);

  /// Ouvre la fiche de l'annonce signalée pour vérifier si le motif est fondé
  /// (APP-121). La carte ne montre qu'un résumé — impossible de trancher sans
  /// voir l'annonce elle-même. Retourne un message d'erreur si le chargement
  /// échoue (annonce supprimée entre-temps).
  Future<String?> ouvrirAnnonceSignalee(LogementReport signalement) async {
    try {
      final logement = await _logements.getLogement(signalement.logementId);
      await _nav.navigateTo(
        Routes.logementDetailView,
        arguments: LogementDetailViewArguments(logement: logement),
      );
      return null;
    } on ApiException catch (e) {
      return e.isNotFound ? "Cette annonce n'existe plus" : e.message;
    }
  }

  List<MessageReport> signalements = [];

  /// File des annonces signalées (APP-121). Une annonce suspendue en sort
  /// automatiquement : le dossier est clos côté serveur.
  List<LogementReport> annoncesSignalees = [];

  /// Onglet courant : les deux files vivent dans le même écran de modération,
  /// mais ne se mélangent pas — les décisions n'ont rien à voir.
  FileModeration file = FileModeration.messages;

  String? errorMessage;
  int total = 0;

  int _page = 0;
  bool _hasNext = false;

  bool get peutChargerPlus => _hasNext && !isBusy;

  Future<void> load() async {
    _page = 0;
    setBusy(true);
    try {
      if (file == FileModeration.messages) {
        final result = await _admin.signalements();
        signalements = result.signalements;
        _hasNext = result.hasNext;
        total = result.total;
      } else {
        final result = await _admin.annoncesSignalees();
        annoncesSignalees = result.signalements;
        _hasNext = result.hasNext;
        total = result.total;
      }
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Change de file et recharge. Chaque file a sa propre pagination.
  Future<void> setFile(FileModeration nouvelle) async {
    if (file == nouvelle) return;
    file = nouvelle;
    await load();
  }

  /// Retire une annonce signalée. Elle quitte alors la file d'elle-même :
  /// le serveur exclut les annonces suspendues des signalements en attente.
  Future<String?> retirerAnnonce(LogementReport signalement, String motif) async {
    final saisie = motif.trim();
    if (saisie.isEmpty) return 'Le motif est obligatoire';

    try {
      await _admin.suspendreLogement(signalement.logementId, saisie);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> chargerPlus() async {
    if (!peutChargerPlus) return;
    setBusy(true);
    try {
      if (file == FileModeration.messages) {
        final result = await _admin.signalements(page: _page + 1);
        signalements = [...signalements, ...result.signalements];
        _hasNext = result.hasNext;
      } else {
        final result = await _admin.annoncesSignalees(page: _page + 1);
        annoncesSignalees = [...annoncesSignalees, ...result.signalements];
        _hasNext = result.hasNext;
      }
      _page++;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Masque le message signalé, puis recharge la file.
  ///
  /// Le rechargement est nécessaire et pas seulement confortable : un même
  /// message peut avoir été signalé par plusieurs personnes. Le masquer fait
  /// disparaître TOUTES ses lignes de la file, pas seulement celle sur
  /// laquelle le modérateur a cliqué — retirer une seule carte localement
  /// laisserait les autres en place, et un second clic échouerait.
  ///
  /// Retourne null si OK, un message d'erreur sinon.
  Future<String?> masquer(MessageReport signalement, String note) async {
    try {
      await _admin.masquerMessage(signalement.messageId, note);
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

/// Les deux files de l'écran de modération (APP-121).
enum FileModeration {
  messages,
  annonces;

  String get label => switch (this) {
        messages => 'Messages',
        annonces => 'Annonces',
      };
}
