import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/alternant_dashboard.dart';

/// Service des tableaux de bord.
class DashboardService {
  final ApiClient _api;

  DashboardService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /dashboard/alternant — données du dashboard de l'utilisateur connecté
  Future<AlternantDashboard> getAlternantDashboard() async {
    final data =
        await _api.get<Map<String, dynamic>>('/dashboard/alternant');
    return AlternantDashboard.fromJson(data);
  }
}
