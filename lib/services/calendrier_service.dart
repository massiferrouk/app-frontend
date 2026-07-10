import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/alternant_profile.dart';
import '../shared/models/mes_semaines.dart';

/// Service du calendrier d'alternance.
class CalendrierService {
  final ApiClient _api;

  CalendrierService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /calendrier/mes-semaines — calendrier complet de l'utilisateur
  Future<MesSemaines> getMesSemaines() async {
    final data =
        await _api.get<Map<String, dynamic>>('/calendrier/mes-semaines');
    return MesSemaines.fromJson(data);
  }

  /// PATCH /calendrier/{profileId}/semaines/{semaine}
  /// Modifie manuellement une semaine (label A/B + raison).
  Future<AlternanceSemaine> overrideSemaine({
    required String profileId,
    required DateTime semaine,
    required String label,
    required String reason,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/calendrier/$profileId/semaines/${AlternantProfile.toIsoDate(semaine)}',
      data: {'label': label, 'reason': reason},
    );
    return AlternanceSemaine.fromJson(data);
  }
}
