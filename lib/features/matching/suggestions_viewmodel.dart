import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/logement_service.dart';
import '../../services/matching_service.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/matching_suggestion.dart';

/// Filtre d'affichage des suggestions
enum SuggestionFilter { tous, actifs, potentiels }

/// Logique de l'écran des suggestions de matching.
class SuggestionsViewModel extends BaseViewModel {
  final MatchingService _matching;
  final LogementService _logements;
  final NavigationService _nav;

  SuggestionsViewModel(
      {MatchingService? matchingService,
      LogementService? logementService,
      NavigationService? navigationService})
      : _matching = matchingService ?? locator<MatchingService>(),
        _logements = logementService ?? locator<LogementService>(),
        _nav = navigationService ?? locator<NavigationService>();

  /// Ouvre le détail du logement de l'autre alternant (match actif).
  /// La suggestion ne porte que l'id du logement : on le charge avant
  /// d'ouvrir l'écran de détail.
  Future<void> goToLogement(MatchingSuggestion suggestion) async {
    final logementId = suggestion.logementBId;
    if (logementId == null) return; // match potentiel : pas de logement publié

    setBusy(true);
    try {
      final logement = await _logements.getLogement(logementId);
      errorMessage = null;
      setBusy(false);
      await _nav.navigateTo(
        Routes.logementDetailView,
        arguments: LogementDetailViewArguments(logement: logement),
      );
    } on ApiException catch (e) {
      errorMessage = e.message;
      setBusy(false);
    }
  }

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

  /// CTA des matchs potentiels (APP-106) : ouvre la publication de logement,
  /// puis recharge — le match peut devenir actif et l'économie apparaître.
  Future<void> publierLogement() async {
    await _nav.navigateTo(Routes.ajouterLogementView);
    await load();
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

  /// Tap sur une tuile : filtre — re-tap : retour à « tous »
  /// (même comportement que les tuiles de l'écran Compatibilité).
  void setFilter(SuggestionFilter f) {
    filter = (filter == f) ? SuggestionFilter.tous : f;
    notifyListeners();
  }

  /// Meilleure économie mensuelle parmi tous les matchs (0 = aucune) —
  /// affichée en sous-titre de l'écran (APP-107).
  int get economieMax =>
      _all.fold(0, (max, s) => s.economieMensuelle > max ? s.economieMensuelle : max);

  /// Le match mis en avant : le meilleur match ACTIF, hors filtre
  /// « potentiels ». null s'il n'y a aucun match actif.
  MatchingSuggestion? get meilleurMatch {
    if (filter == SuggestionFilter.potentiels) return null;
    final tries = suggestions;
    if (tries.isEmpty || !tries.first.isMatchActif) return null;
    return tries.first;
  }

  /// Les matchs affichés en cartes compactes (tous sauf le meilleur)
  List<MatchingSuggestion> get autresSuggestions {
    final meilleur = meilleurMatch;
    if (meilleur == null) return suggestions;
    return suggestions.where((s) => s != meilleur).toList();
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
