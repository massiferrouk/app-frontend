import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/dashboard_service.dart';
import '../../shared/models/alternant_dashboard.dart';

/// Logique du dashboard alternant.
class HomeAlternantViewModel extends BaseViewModel {
  final DashboardService _dashboard;

  HomeAlternantViewModel({DashboardService? dashboardService})
      : _dashboard = dashboardService ?? locator<DashboardService>();

  AlternantDashboard? dashboard;
  String? errorMessage;

  /// Chargement initial ET pull-to-refresh
  Future<void> load() async {
    setBusy(true);
    try {
      dashboard = await _dashboard.getAlternantDashboard();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }
}
