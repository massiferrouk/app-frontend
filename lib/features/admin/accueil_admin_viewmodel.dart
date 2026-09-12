import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/admin_service.dart';
import '../../shared/models/admin_dashboard.dart';

/// Logique de l'accueil administrateur (APP-121).
class AccueilAdminViewModel extends BaseViewModel {
  final AdminService _admin;

  AccueilAdminViewModel({AdminService? adminService})
      : _admin = adminService ?? locator<AdminService>();

  AdminDashboard? dashboard;
  String? errorMessage;

  /// Stale-while-revalidate (APP-122) : l'accueil connu s'affiche tout de suite
  /// et se rafraîchit en fond, plus de spinner à chaque retour sur l'onglet.
  Future<void> load() async {
    final cache = _admin.cachedDashboard;
    if (cache != null) {
      dashboard = cache;
      notifyListeners();
    } else {
      setBusy(true);
    }
    try {
      dashboard = await _admin.dashboard();
      errorMessage = null;
    } on ApiException catch (e) {
      if (dashboard == null) errorMessage = e.message;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  /// Y a-t-il quelque chose qui demande une action ?
  /// Les deux files comptent : une annonce signalée est aussi urgente qu'un
  /// message, et n'en tenir compte que d'une seule masquerait l'autre.
  bool get aDesSignalements =>
      (dashboard?.signalementsEnAttente ?? 0) > 0 ||
      (dashboard?.annoncesSignalees ?? 0) > 0;

  /// Total des deux files, pour la carte d'alerte.
  int get totalSignalements =>
      (dashboard?.signalementsEnAttente ?? 0) +
      (dashboard?.annoncesSignalees ?? 0);
}
