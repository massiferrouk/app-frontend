import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/logement.dart';

/// Service des logements.
class LogementService {
  final ApiClient _api;

  LogementService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /logements/mes-logements — tous mes logements, brouillons inclus
  Future<List<Logement>> getMesLogements() async {
    final data = await _api.get<List<dynamic>>('/logements/mes-logements');
    return data
        .map((e) => Logement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PUT /logements/{id}/publish — BROUILLON → ACTIF
  Future<Logement> publish(String logementId) async {
    final data = await _api
        .put<Map<String, dynamic>>('/logements/$logementId/publish');
    return Logement.fromJson(data);
  }

  /// PATCH /logements/{id}/ville — associe le logement à villeA ou villeB
  /// du profil alternant (409 si un logement occupe déjà cette ville).
  Future<Logement> associerVille(
      String logementId, VilleAssociee ville) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/logements/$logementId/ville',
      data: {'villeAssociee': ville.toJson()},
    );
    return Logement.fromJson(data);
  }
}
