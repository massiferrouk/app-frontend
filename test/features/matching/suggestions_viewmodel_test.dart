import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/matching/suggestions_viewmodel.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/matching_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/matching_suggestion.dart';

class MockMatchingService extends Mock implements MatchingService {}

class MockLogementService extends Mock implements LogementService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockMatchingService matchingService;
  late SuggestionsViewModel viewModel;

  MatchingSuggestion build({
    required String prenom,
    required double score,
    required AccordType type,
    required bool actif,
  }) =>
      MatchingSuggestion(
        profileId: 'p-$prenom',
        userId: 'u-$prenom',
        prenom: prenom,
        nom: 'Test',
        villeA: 'Paris',
        villeB: 'Lyon',
        score: score,
        scorePercent: (score * 100).round(),
        typePropose: type,
        isMatchActif: actif,
        messageMatchPotentiel:
            actif ? null : 'Si tu publies un logement à Lyon…',
        nbSemainesEchange: 3,
        nbSemainesColocation: 0,
        nbSemainesChevauchement: 1,
      );

  late MockNavigationService navigationService;

  setUp(() {
    matchingService = MockMatchingService();
    navigationService = MockNavigationService();
    viewModel = SuggestionsViewModel(
      matchingService: matchingService,
      logementService: MockLogementService(),
      navigationService: navigationService,
    );
  });

  test('publierLogement : ouvre la publication puis recharge (APP-106)',
      () async {
    when(() => navigationService.navigateTo(any()))
        .thenAnswer((_) async => null);
    when(() => matchingService.getSuggestions()).thenAnswer((_) async => []);

    await viewModel.publierLogement();

    verify(() => navigationService.navigateTo(Routes.ajouterLogementView))
        .called(1);
    verify(() => matchingService.getSuggestions()).called(1);
  });

  group('SuggestionsViewModel', () {
    test('trie : actifs d\'abord, puis score décroissant', () async {
      when(() => matchingService.getSuggestions()).thenAnswer((_) async => [
            build(
                prenom: 'PotentielFort',
                score: 0.98,
                type: AccordType.ECHANGE_TOTAL,
                actif: false),
            build(
                prenom: 'ActifFaible',
                score: 0.65,
                type: AccordType.ECHANGE_PARTIEL,
                actif: true),
            build(
                prenom: 'ActifFort',
                score: 0.92,
                type: AccordType.ECHANGE_TOTAL,
                actif: true),
          ]);

      await viewModel.load();
      final result = viewModel.suggestions;

      // Les 2 actifs avant le potentiel, même si le potentiel a le meilleur score
      expect(result.map((s) => s.prenom).toList(),
          ['ActifFort', 'ActifFaible', 'PotentielFort']);
    });

    test('filtre actifs / potentiels / tous', () async {
      when(() => matchingService.getSuggestions()).thenAnswer((_) async => [
            build(
                prenom: 'A',
                score: 0.9,
                type: AccordType.ECHANGE_TOTAL,
                actif: true),
            build(
                prenom: 'B',
                score: 0.7,
                type: AccordType.COLOCATION_TOURNANTE,
                actif: false),
          ]);

      await viewModel.load();

      expect(viewModel.nbActifs, 1);
      expect(viewModel.nbPotentiels, 1);

      viewModel.setFilter(SuggestionFilter.actifs);
      expect(viewModel.suggestions, hasLength(1));
      expect(viewModel.suggestions.first.isMatchActif, isTrue);

      viewModel.setFilter(SuggestionFilter.potentiels);
      expect(viewModel.suggestions, hasLength(1));
      expect(viewModel.suggestions.first.isMatchActif, isFalse);

      viewModel.setFilter(SuggestionFilter.tous);
      expect(viewModel.suggestions, hasLength(2));
    });

    test('erreur API : message stocké, liste vide', () async {
      when(() => matchingService.getSuggestions())
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur',
        statusCode: 0,
      ));

      await viewModel.load();

      expect(viewModel.suggestions, isEmpty);
      expect(viewModel.errorMessage, contains('Impossible'));
    });

    test('displayName abrège le nom de famille', () {
      final s = build(
          prenom: 'Thomas',
          score: 0.9,
          type: AccordType.ECHANGE_TOTAL,
          actif: true);

      expect(s.displayName, 'Thomas T.');
      expect(s.initials, 'TT');
    });
  });
}
