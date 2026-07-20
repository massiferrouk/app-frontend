import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/candidature.dart';
import '../shared/models/enums.dart';

/// Suivi des candidatures logement (APP-117).
class CandidatureService {
  final ApiClient _api;

  CandidatureService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /candidatures — mes annonces suivies, la plus récemment modifiée d'abord
  Future<List<Candidature>> getMesCandidatures() async {
    final data = await _api.get<List<dynamic>>('/candidatures');
    return data
        .map((e) => Candidature.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /candidatures — suit une annonce.
  /// Idempotent côté serveur : re-suivre ne duplique pas et n'écrase pas le
  /// statut déjà choisi (sauf « À contacter » → « Contacté »).
  Future<Candidature> suivre({
    required String logementId,
    CandidatureStatut? statut,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/candidatures',
      data: {
        'logementId': logementId,
        if (statut != null) 'statut': statut.toJson(),
      },
    );
    return Candidature.fromJson(data);
  }

  /// PATCH /candidatures/{id} — fait évoluer le statut (et la note perso)
  Future<Candidature> updateStatut({
    required String candidatureId,
    required CandidatureStatut statut,
    String? note,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/candidatures/$candidatureId',
      data: {'statut': statut.toJson(), 'note': note},
    );
    return Candidature.fromJson(data);
  }

  /// DELETE /candidatures/{id} — retire l'annonce du suivi
  Future<void> delete(String candidatureId) async {
    await _api.delete('/candidatures/$candidatureId');
  }
}
