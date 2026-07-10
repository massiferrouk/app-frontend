import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/accord.dart';

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
