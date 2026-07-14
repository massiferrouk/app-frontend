import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/accord_service.dart';
import '../../services/dashboard_service.dart';
import '../../shared/models/accord_summary.dart';
import '../../shared/models/alternant_dashboard.dart';

/// Logique du dashboard alternant.
class HomeAlternantViewModel extends BaseViewModel {
  final DashboardService _dashboard;
  final AccordService _accords;
  final NavigationService _nav;

  HomeAlternantViewModel(
      {DashboardService? dashboardService,
      AccordService? accordService,
      NavigationService? navigationService})
      : _dashboard = dashboardService ?? locator<DashboardService>(),
        _accords = accordService ?? locator<AccordService>(),
        _nav = navigationService ?? locator<NavigationService>();

  void goToCalendrier() => _nav.navigateTo(Routes.monCalendrierView);

  /// Ouvre le détail d'un accord (accepter / refuser / consulter).
  /// Le dashboard ne porte qu'un résumé : on récupère l'accord complet
  /// avant d'ouvrir l'écran de détail, puis on recharge au retour.
  Future<void> goToAccordDetail(AccordSummary summary) async {
    setBusy(true);
    try {
      final accord = await _accords.getAccord(summary.id);
      errorMessage = null;
      setBusy(false);
      await _nav.navigateTo(
        Routes.accordDetailView,
        arguments: AccordDetailViewArguments(accord: accord),
      );
      await load(); // statut peut avoir changé (accepté / refusé)
    } on ApiException catch (e) {
      errorMessage = e.message;
      setBusy(false);
    }
  }

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
