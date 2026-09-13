import 'package:flutter/foundation.dart';

import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/matching_suggestion.dart';

/// Service du matching.
class MatchingService {
  final ApiClient _api;

  MatchingService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// Dernières suggestions récupérées (APP-122). Le service est un singleton :
  /// ce cache permet d'afficher tout de suite les blocs qui dépendent du
  /// matching (bloc compatibilité sur une fiche annonce, carte du match dans le
  /// chat) puis de rafraîchir en fond, au lieu de les voir apparaître en retard.
  List<MatchingSuggestion>? cachedSuggestions;

  /// Compteur bumpé à chaque rafraîchissement en fond des suggestions
  /// (APP-122). L'onglet Matches, qui reste monté dans l'IndexedStack, écoute
  /// ce signal pour recharger sa liste depuis [cachedSuggestions] SANS spinner
  /// quand une notification « nouveau match » arrive en temps réel — sinon le
  /// nouveau match n'apparaissait qu'après un pull-to-refresh manuel.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// GET /matching/suggestions — top 20 matches triés par score décroissant,
  /// matchs actifs ET potentiels confondus.
  Future<List<MatchingSuggestion>> getSuggestions() async {
    final data = await _api.get<List<dynamic>>('/matching/suggestions');
    final suggestions = data
        .map((e) => MatchingSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
    cachedSuggestions = suggestions;
    return suggestions;
  }

  /// Recharge les suggestions en fond puis prévient les abonnés via [revision].
  /// Erreurs silencieuses : un échec réseau ne doit pas casser la notification
  /// temps réel qui a déclenché ce rafraîchissement.
  Future<void> refreshEnFond() async {
    try {
      await getSuggestions();
      revision.value++;
    } catch (_) {
      // silencieux — la liste garde son état actuel
    }
  }
}
