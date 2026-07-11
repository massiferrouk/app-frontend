import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/dashboard_service.dart';
import '../../shared/models/proprietaire_dashboard.dart';

/// Logique du dashboard propriétaire.
class HomeProprioViewModel extends BaseViewModel {
  final DashboardService _dashboard;

  HomeProprioViewModel({DashboardService? dashboardService})
      : _dashboard = dashboardService ?? locator<DashboardService>();

  ProprietaireDashboard? dashboard;
  String? errorMessage;

  Future<void> load() async {
    setBusy(true);
    try {
      dashboard = await _dashboard.getProprietaireDashboard();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Alertes dérivées des données : logements en brouillon jamais publiés,
  /// logements actifs sans locataire.
  List<String> get alertes {
    final d = dashboard;
    if (d == null) return [];

    final result = <String>[];
    final brouillons = d.nbLogementsTotaux - d.nbLogementsActifs;
    if (brouillons > 0) {
      result.add(brouillons > 1
          ? '$brouillons logements en brouillon — pense à les publier'
          : '1 logement en brouillon — pense à le publier');
    }
    final vacants = d.logements
        .where((l) => !l.isOccupe && l.statut.name == 'ACTIF')
        .length;
    if (vacants > 0) {
      result.add(vacants > 1
          ? '$vacants logements actifs sans locataire'
          : '1 logement actif sans locataire');
    }
    return result;
  }
}
