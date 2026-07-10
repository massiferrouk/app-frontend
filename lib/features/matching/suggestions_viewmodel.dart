import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/matching_service.dart';
import '../../shared/models/matching_suggestion.dart';

/// Filtre d'affichage des suggestions
enum SuggestionFilter { tous, actifs, potentiels }

/// Logique de l'écran des suggestions de matching.
class SuggestionsViewModel extends BaseViewModel {
  final MatchingService _matching;

  SuggestionsViewModel({MatchingService? matchingService})
      : _matching = matchingService ?? locator<MatchingService>();

  List<MatchingSuggestion> _all = [];
  String? errorMessage;
  SuggestionFilter filter = SuggestionFilter.tous;

  Future<void> load() async {
    setBusy(true);
    try {
      _all = await _matching.getSuggestions();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  void setFilter(SuggestionFilter f) {
    filter = f;
    notifyListeners();
  }

  /// Suggestions filtrées ET ordonnées : matchs actifs d'abord,
  /// puis par score décroissant (règle métier US-013).
  List<MatchingSuggestion> get suggestions {
    final filtered = switch (filter) {
      SuggestionFilter.tous => _all,
      SuggestionFilter.actifs => _all.where((s) => s.isMatchActif).toList(),
      SuggestionFilter.potentiels =>
        _all.where((s) => !s.isMatchActif).toList(),
    };

    final sorted = List<MatchingSuggestion>.from(filtered)
      ..sort((a, b) {
        // Actifs avant potentiels
        if (a.isMatchActif != b.isMatchActif) {
          return a.isMatchActif ? -1 : 1;
        }
        // Puis score décroissant
        return b.score.compareTo(a.score);
      });
    return sorted;
  }

  int get nbActifs => _all.where((s) => s.isMatchActif).length;
  int get nbPotentiels => _all.where((s) => !s.isMatchActif).length;
}
