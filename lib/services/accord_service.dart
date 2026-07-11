import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/accord.dart';
import '../shared/models/alternant_profile.dart';
import '../shared/models/enums.dart';

/// Service des accords.
class AccordService {
  final ApiClient _api;

  AccordService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /accords/mes-accords — le backend renvoie une Page Spring :
  /// on extrait le champ content.
  Future<List<Accord>> getMesAccords() async {
    final data =
        await _api.get<Map<String, dynamic>>('/accords/mes-accords');
    return (data['content'] as List? ?? [])
        .map((e) => Accord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /accords — envoie une demande d'accord (statut EN_ATTENTE,
  /// expire après 72h, notifie le destinataire côté backend)
  Future<Accord> createAccord({
    required String receiverId,
    required AccordType type,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? messageInitial,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/accords',
      data: {
        'receiverId': receiverId,
        'type': type.toJson(),
        'dateDebut': AlternantProfile.toIsoDate(dateDebut),
        'dateFin': AlternantProfile.toIsoDate(dateFin),
        'messageInitial': messageInitial,
      },
    );
    return Accord.fromJson(data);
  }

  Future<Accord> accept(String accordId) async {
    final data =
        await _api.put<Map<String, dynamic>>('/accords/$accordId/accept');
    return Accord.fromJson(data);
  }

  Future<Accord> refuse(String accordId) async {
    final data =
        await _api.put<Map<String, dynamic>>('/accords/$accordId/refuse');
    return Accord.fromJson(data);
  }

  Future<Accord> cancel(String accordId) async {
    final data =
        await _api.put<Map<String, dynamic>>('/accords/$accordId/cancel');
    return Accord.fromJson(data);
  }
}
