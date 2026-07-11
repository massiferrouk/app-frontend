import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/dashboard_service.dart';
import '../../shared/models/alternant_dashboard.dart';

/// Logique du dashboard alternant.
class HomeAlternantViewModel extends BaseViewModel {
  final DashboardService _dashboard;
  final NavigationService _nav;

  HomeAlternantViewModel(
      {DashboardService? dashboardService,
      NavigationService? navigationService})
      : _dashboard = dashboardService ?? locator<DashboardService>(),
        _nav = navigationService ?? locator<NavigationService>();

  void goToCalendrier() => _nav.navigateTo(Routes.monCalendrierView);

  void goToNotifications() => _nav.navigateTo(
        Routes.notificationsView,
        arguments: const NotificationsViewArguments(standalone: true),
      );

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
