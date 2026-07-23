import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/admin_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/logement.dart';

/// Logique de l'écran Annonces côté administration (APP-121).
class AnnoncesViewModel extends BaseViewModel {
  final AdminService _admin;

  AnnoncesViewModel({AdminService? adminService})
      : _admin = adminService ?? locator<AdminService>();

  List<Logement> annonces = [];
  String? errorMessage;
  int total = 0;

  /// Filtre de statut — null = toutes
  LogementStatut? filtreStatut;

  int _page = 0;
  bool _hasNext = false;

  bool get peutChargerPlus => _hasNext && !isBusy;

  Future<void> load() async {
    _page = 0;
    setBusy(true);
    try {
      final result = await _admin.logements(statut: filtreStatut);
      annonces = result.logements;
      _hasNext = result.hasNext;
      total = result.total;
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  Future<void> chargerPlus() async {
    if (!peutChargerPlus) return;
    setBusy(true);
    try {
      final result =
          await _admin.logements(statut: filtreStatut, page: _page + 1);
      annonces = [...annonces, ...result.logements];
      _page++;
      _hasNext = result.hasNext;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Repasser le même filtre le retire (bascule).
  Future<void> setFiltreStatut(LogementStatut? statut) async {
    filtreStatut = filtreStatut == statut ? null : statut;
    await load();
  }

  Future<String?> suspendre(Logement logement, String motif) async {
    final saisie = motif.trim();
    if (saisie.isEmpty) return 'Le motif est obligatoire';
    return _appliquer(() => _admin.suspendreLogement(logement.id, saisie));
  }

  Future<String?> republier(Logement logement) =>
      _appliquer(() => _admin.republierLogement(logement.id));

  /// Applique la décision puis recharge : le statut affiché doit venir du
  /// serveur. Retourne null si OK, un message d'erreur sinon.
  Future<String?> _appliquer(Future<Logement> Function() action) async {
    try {
      await action();
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
