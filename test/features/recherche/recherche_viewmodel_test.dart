import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/recherche/recherche_viewmodel.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';

class MockLogementService extends Mock implements LogementService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockLogementService logementService;
  late RechercheViewModel viewModel;

  Logement build(String id) => Logement.fromJson({
        'id': id,
        'ownerId': 'owner-1',
        'adresse': '1 rue Test',
        'ville': 'Paris',
        'codePostal': '75001',
        'type': 'STUDIO',
        'surface': 25.0,
        'nbPieces': 1,
        'loyer': 700.0,
        'charges': 50.0,
        'statut': 'ACTIF',
        'isVerified': true,
        'isMeuble': true,
      });

  void stubSearch({required List<Logement> logements, bool hasNext = false}) {
    when(() => logementService.search(
          ville: any(named: 'ville'),
          loyerMax: any(named: 'loyerMax'),
          surfaceMin: any(named: 'surfaceMin'),
          meuble: any(named: 'meuble'),
          type: any(named: 'type'),
          page: any(named: 'page'),
        )).thenAnswer((_) async => (logements: logements, hasNext: hasNext));
  }

  setUpAll(() => registerFallbackValue(LogementType.STUDIO));

  setUp(() {
    logementService = MockLogementService();
    viewModel = RechercheViewModel(
      logementService: logementService,
      navigationService: MockNavigationService(),
    );
  });

  group('search', () {
    test('charge la première page', () async {
      stubSearch(logements: [build('l1'), build('l2')], hasNext: true);

      await viewModel.search();

      expect(viewModel.resultats, hasLength(2));
      expect(viewModel.hasNext, isTrue);
    });

    test('les filtres sont transmis au service', () async {
      stubSearch(logements: []);
      viewModel.villeController.text = 'Lyon';
      viewModel.loyerMax = 700;
      viewModel.meubleUniquement = true;
      viewModel.type = LogementType.T1;

      await viewModel.search();

      verify(() => logementService.search(
            ville: 'Lyon',
            loyerMax: 700,
            surfaceMin: null,
            meuble: true,
            type: LogementType.T1,
            page: 0,
          )).called(1);
    });

    test('re-taper un filtre actif le désactive', () async {
      stubSearch(logements: []);

      viewModel.setLoyerMax(700);
      expect(viewModel.loyerMax, 700);

      viewModel.setLoyerMax(700);
      expect(viewModel.loyerMax, isNull);
    });

    test('erreur API : message stocké', () async {
      when(() => logementService.search(
            ville: any(named: 'ville'),
            loyerMax: any(named: 'loyerMax'),
            surfaceMin: any(named: 'surfaceMin'),
            meuble: any(named: 'meuble'),
            type: any(named: 'type'),
            page: any(named: 'page'),
          )).thenThrow(const ApiException(
          code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.search();

      expect(viewModel.errorMessage, 'Hors ligne');
    });
  });

  group('loadMore (infinite scroll)', () {
    test('concatène la page suivante', () async {
      stubSearch(logements: [build('l1')], hasNext: true);
      await viewModel.search();

      stubSearch(logements: [build('l2')], hasNext: false);
      await viewModel.loadMore();

      expect(viewModel.resultats.map((l) => l.id), ['l1', 'l2']);
      expect(viewModel.hasNext, isFalse);
    });

    test('pas de page suivante : aucun appel', () async {
      stubSearch(logements: [build('l1')], hasNext: false);
      await viewModel.search();
      clearInteractions(logementService);

      await viewModel.loadMore();

      verifyNever(() => logementService.search(
            ville: any(named: 'ville'),
            loyerMax: any(named: 'loyerMax'),
            surfaceMin: any(named: 'surfaceMin'),
            meuble: any(named: 'meuble'),
            type: any(named: 'type'),
            page: any(named: 'page'),
          ));
    });
  });
}
