import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/alternant_dashboard.dart';
import '../shared/models/proprietaire_dashboard.dart';

/// Service des tableaux de bord.
class DashboardService {
  final ApiClient _api;

  DashboardService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// Derniers dashboards récupérés (APP-122) — alimentent le stale-while-
  /// revalidate des accueils : on réaffiche l'accueil connu tout de suite et on
  /// rafraîchit en fond, au lieu d'un spinner à chaque retour sur l'onglet.
  AlternantDashboard? cachedAlternantDashboard;
  ProprietaireDashboard? cachedProprietaireDashboard;

  /// GET /dashboard/alternant — données du dashboard de l'utilisateur connecté
  Future<AlternantDashboard> getAlternantDashboard() async {
    final data =
        await _api.get<Map<String, dynamic>>('/dashboard/alternant');
    final dashboard = AlternantDashboard.fromJson(data);
    cachedAlternantDashboard = dashboard;
    return dashboard;
  }

  /// GET /dashboard/proprietaire — KPIs et logements du propriétaire
  Future<ProprietaireDashboard> getProprietaireDashboard() async {
    final data =
        await _api.get<Map<String, dynamic>>('/dashboard/proprietaire');
    final dashboard = ProprietaireDashboard.fromJson(data);
    cachedProprietaireDashboard = dashboard;
    return dashboard;
  }
}
