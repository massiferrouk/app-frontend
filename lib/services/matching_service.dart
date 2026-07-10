import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/matching_suggestion.dart';

/// Service du matching.
class MatchingService {
  final ApiClient _api;

  MatchingService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /matching/suggestions — top 20 matches triés par score décroissant,
  /// matchs actifs ET potentiels confondus.
  Future<List<MatchingSuggestion>> getSuggestions() async {
    final data = await _api.get<List<dynamic>>('/matching/suggestions');
    return data
        .map((e) => MatchingSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
