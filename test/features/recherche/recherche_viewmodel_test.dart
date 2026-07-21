import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/recherche/recherche_viewmodel.dart';
import 'package:studup_app/services/candidature_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/matching_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/candidature.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';
import 'package:studup_app/shared/models/matching_suggestion.dart';

class MockLogementService extends Mock implements LogementService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockMatchingService extends Mock implements MatchingService {}

class MockProfileService extends Mock implements ProfileService {}

class MockCandidatureService extends Mock implements CandidatureService {}

void main() {
  late MockLogementService logementService;
  late MockMatchingService matchingService;
  late MockProfileService profileService;
  late MockCandidatureService candidatureService;
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
          tri: any(named: 'tri'),
          page: any(named: 'page'),
        )).thenAnswer((_) async =>
        (logements: logements, hasNext: hasNext, total: logements.length));
  }

  MatchingSuggestion buildSuggestion({
    String villeA = 'Lyon',
    String villeB = 'Paris',
    int economie = 0,
  }) =>
      MatchingSuggestion.fromJson({
        'profileId': 'p-1',
        'userId': 'u-1',
        'prenom': 'Thomas',
        'nom': 'Durand',
        'villeA': villeA,
        'villeB': villeB,
        'score': 0.75,
        'scorePercent': 75,
        'typePropose': 'ECHANGE_PARTIEL',
        'isMatchActif': true,
        'nbSemainesEchange': 3,
        'nbSemainesColocation': 0,
        'nbSemainesChevauchement': 1,
        'semaines': const [],
        'economieMensuelle': economie,
      });

  setUpAll(() => registerFallbackValue(LogementType.STUDIO));

  setUp(() {
    logementService = MockLogementService();
    matchingService = MockMatchingService();
    profileService = MockProfileService();
    candidatureService = MockCandidatureService();
    // Par défaut : aucune annonce suivie → aucun badge sur les cartes
    when(() => candidatureService.getMesCandidatures())
        .thenAnswer((_) async => []);
    // Par défaut : étudiant (pas de carte matching)
    when(() => profileService.currentRole())
        .thenAnswer((_) async => UserRole.ETUDIANT);
    viewModel = RechercheViewModel(
      logementService: logementService,
      matchingService: matchingService,
      profileService: profileService,
      candidatureService: candidatureService,
      navigationService: MockNavigationService(),
    );
  });

  group('badges de suivi sur les résultats (APP-119)', () {
    Candidature buildCandidature(String logementId, CandidatureStatut statut) =>
        Candidature(
          id: 'cand-$logementId',
          statut: statut,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          logement: build(logementId),
        );

    test('seules les annonces suivies portent un statut', () async {
      stubSearch(logements: [build('log-1'), build('log-2')]);
      when(() => candidatureService.getMesCandidatures()).thenAnswer(
          (_) async => [buildCandidature('log-1', CandidatureStatut.VISITEE)]);

      await viewModel.search();

      // Suivie → badge ; non suivie → rien, la carte reste vierge
      expect(viewModel.statutPour('log-1'), CandidatureStatut.VISITEE);
      expect(viewModel.statutPour('log-2'), isNull);
    });

    test('échec du chargement des candidatures : recherche intacte', () async {
      stubSearch(logements: [build('log-1')]);
      when(() => candidatureService.getMesCandidatures()).thenThrow(
          const ApiException(
              code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.search();

      // Les résultats s'affichent quand même, simplement sans badge
      expect(viewModel.resultats, hasLength(1));
      expect(viewModel.statutPour('log-1'), isNull);
      expect(viewModel.errorMessage, isNull);
    });
  });

  group('carte matching dans la recherche (APP-104)', () {
    test('alternant + ville avec matchs : compte et meilleure économie',
        () async {
      stubSearch(logements: []);
      when(() => profileService.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      when(() => matchingService.getSuggestions()).thenAnswer((_) async => [
            buildSuggestion(villeA: 'Marseille', economie: 225),
            buildSuggestion(villeB: 'marseille', economie: 450), // casse ≠
            buildSuggestion(villeA: 'Bordeaux', economie: 900), // hors ville
          ]);
      viewModel.villeController.text = 'Marseille';

      await viewModel.search();

      expect(viewModel.matchsCompatibles, 2);
      expect(viewModel.economieMaxMatchs, 450);
      expect(viewModel.villeMatchs, 'Marseille');
    });

    test('étudiant : jamais d\'appel au matching', () async {
      stubSearch(logements: []);
      viewModel.villeController.text = 'Marseille';

      await viewModel.search();

      expect(viewModel.matchsCompatibles, 0);
      verifyNever(() => matchingService.getSuggestions());
    });

    test('ville vide : pas de carte', () async {
      stubSearch(logements: []);
      when(() => profileService.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);

      await viewModel.search();

      expect(viewModel.matchsCompatibles, 0);
      verifyNever(() => matchingService.getSuggestions());
    });

    test('erreur matching silencieuse : les résultats restent affichés',
        () async {
      stubSearch(logements: [build('l1')]);
      when(() => profileService.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      when(() => matchingService.getSuggestions()).thenThrow(
          const ApiException(
              code: 'NOT_FOUND', message: 'Pas de profil', statusCode: 404));
      viewModel.villeController.text = 'Marseille';

      await viewModel.search();

      expect(viewModel.resultats, hasLength(1));
      expect(viewModel.matchsCompatibles, 0);
    });
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
            tri: 'pertinence',
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
            tri: any(named: 'tri'),
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
            tri: any(named: 'tri'),
            page: any(named: 'page'),
          ));
    });
  });

  group('tri et réinitialisation (APP-117)', () {
    test('setTri relance la recherche avec le tri demandé', () async {
      stubSearch(logements: [build('l1')]);

      viewModel.setTri('prix_asc');
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.tri, 'prix_asc');
      expect(viewModel.triLabel, 'Prix croissant');
      verify(() => logementService.search(
            ville: any(named: 'ville'),
            loyerMax: any(named: 'loyerMax'),
            surfaceMin: any(named: 'surfaceMin'),
            meuble: any(named: 'meuble'),
            type: any(named: 'type'),
            tri: 'prix_asc',
            page: any(named: 'page'),
          )).called(1);
    });

    test('le total remonte pour l\'en-tête de résultats', () async {
      stubSearch(logements: [build('l1'), build('l2')]);
      viewModel.villeController.text = 'Paris';

      await viewModel.search();

      expect(viewModel.totalResultats, 2);
      expect(viewModel.resultatsLabel, '2 logements à Paris');
    });

    test('hasFiltresActifs + resetFiltres remettent tout à zéro', () async {
      stubSearch(logements: []);
      viewModel.villeController.text = 'Lyon';
      viewModel.loyerMax = 700;
      viewModel.meubleUniquement = true;
      viewModel.type = LogementType.T1;
      viewModel.tri = 'prix_desc';

      expect(viewModel.hasFiltresActifs, isTrue);

      viewModel.resetFiltres();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.villeController.text, isEmpty);
      expect(viewModel.loyerMax, isNull);
      expect(viewModel.meubleUniquement, isFalse);
      expect(viewModel.type, isNull);
      expect(viewModel.tri, 'pertinence');
      expect(viewModel.hasFiltresActifs, isFalse);
    });
  });
}
