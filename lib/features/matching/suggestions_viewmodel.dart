import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/matching_service.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/matching_suggestion.dart';

/// Filtre d'affichage des suggestions
enum SuggestionFilter { tous, actifs, potentiels }

/// Logique de l'écran des suggestions de matching.
class SuggestionsViewModel extends BaseViewModel {
  final MatchingService _matching;
  final NavigationService _nav;

  SuggestionsViewModel(
      {MatchingService? matchingService,
      NavigationService? navigationService})
      : _matching = matchingService ?? locator<MatchingService>(),
        _nav = navigationService ?? locator<NavigationService>();

  /// Ouvre un chat avec ce match. conversationId vide = nouvelle
  /// conversation, créée côté backend au premier message.
  void goToChat(MatchingSuggestion suggestion) {
    _nav.navigateTo(
      Routes.chatView,
      arguments: ChatViewArguments(
        conversation: ConversationSummary(
          conversationId: '',
          partnerId: suggestion.userId,
          partnerName: suggestion.displayName,
          lastMessage: '',
          unreadCount: 0,
        ),
      ),
    );
  }

  /// Ouvre le calendrier de compatibilité avec ce match.
  /// Les données voyagent en argument de route : aucun appel réseau.
  void goToCompatibilite(MatchingSuggestion suggestion) {
    _nav.navigateTo(
      Routes.compatibiliteView,
      arguments: CompatibiliteViewArguments(suggestion: suggestion),
    );
  }

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
