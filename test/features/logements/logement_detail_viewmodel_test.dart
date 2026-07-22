import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/app/app.router.dart';
import 'package:studup_app/features/logements/logement_detail_viewmodel.dart';
import 'package:studup_app/services/candidature_service.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/matching_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';
import 'package:studup_app/shared/models/matching_suggestion.dart';

class MockLogementService extends Mock implements LogementService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock implements NavigationService {}

class MockMatchingService extends Mock implements MatchingService {}

class MockCandidatureService extends Mock implements CandidatureService {}

void main() {
  late MockLogementService logementService;
  late MockProfileService profileService;
  late MockMatchingService matchingService;
  late MockCandidatureService candidatureService;
  late MockNavigationService navigationService;
  late LogementDetailViewModel viewModel;

  final logement = Logement.fromJson({
    'id': 'log-1',
    'ownerId': 'owner-1',
    'adresse': '12 rue de la Paix',
    'ville': 'Paris',
    'codePostal': '75001',
    'type': 'STUDIO',
    'surface': 25.0,
    'nbPieces': 1,
    'loyer': 800.0,
    'charges': 50.0,
    'statut': 'ACTIF',
    'isVerified': true,
    'isMeuble': true,
  });

  MatchingSuggestion buildSuggestion(String userId) =>
      MatchingSuggestion.fromJson({
        'profileId': 'p-1',
        'userId': userId,
        'prenom': 'Thomas',
        'nom': 'Durand',
        'villeA': 'Lyon',
        'villeB': 'Paris',
        'score': 0.87,
        'scorePercent': 87,
        'typePropose': 'ECHANGE_PARTIEL',
        'isMatchActif': true,
        'nbSemainesEchange': 3,
        'nbSemainesColocation': 0,
        'nbSemainesChevauchement': 1,
        'semaines': const [],
        'economieMensuelle': 225,
      });

  setUp(() {
    logementService = MockLogementService();
    profileService = MockProfileService();
    matchingService = MockMatchingService();
    when(() => profileService.currentUserId())
        .thenAnswer((_) async => 'moi');
    // Par défaut : étudiant, pas de section compatibilité
    when(() => profileService.currentRole())
        .thenAnswer((_) async => UserRole.ETUDIANT);
    // Rechargement du logement complet dans loadExtras
    when(() => logementService.getLogement('log-1'))
        .thenAnswer((_) async => logement);
    // APP-117 : loadExtras vérifie si l'annonce est déjà suivie
    candidatureService = MockCandidatureService();
    when(() => candidatureService.getMesCandidatures())
        .thenAnswer((_) async => []);
    navigationService = MockNavigationService();
    when(() => navigationService.navigateTo(any(),
        arguments: any(named: 'arguments'))).thenAnswer((_) async => null);
    viewModel = LogementDetailViewModel(
      logement: logement,
      logementService: logementService,
      matchingService: matchingService,
      profileService: profileService,
      candidatureService: candidatureService,
      navigationService: navigationService,
    );
  });

  group('compatibilité annonceur (APP-104)', () {
    setUp(() {
      // Les extras secondaires échouent silencieusement dans ces tests
    });

    test('alternant + annonceur dans mes suggestions : match exposé',
        () async {
      when(() => profileService.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      when(() => matchingService.getSuggestions()).thenAnswer(
          (_) async => [buildSuggestion('u-9'), buildSuggestion('owner-1')]);

      await viewModel.loadExtras();

      expect(viewModel.matchAnnonceur, isNotNull);
      expect(viewModel.matchAnnonceur!.userId, 'owner-1');
      expect(viewModel.matchAnnonceur!.scorePercent, 87);
    });

    test('annonceur absent des suggestions : pas de section', () async {
      when(() => profileService.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      when(() => matchingService.getSuggestions())
          .thenAnswer((_) async => [buildSuggestion('u-9')]);

      await viewModel.loadExtras();

      expect(viewModel.matchAnnonceur, isNull);
    });

    test('étudiant : jamais d\'appel au matching', () async {
      await viewModel.loadExtras();

      expect(viewModel.matchAnnonceur, isNull);
      verifyNever(() => matchingService.getSuggestions());
    });

    test('mon propre logement : jamais d\'appel au matching', () async {
      when(() => profileService.currentUserId())
          .thenAnswer((_) async => 'owner-1'); // je suis l'annonceur

      await viewModel.loadExtras();

      verifyNever(() => matchingService.getSuggestions());
    });
  });

  group('contacter l\'annonce d\'un match (APP-120)', () {
    /// Place l'annonceur parmi mes matches
    Future<void> chargerAvecMatch() async {
      when(() => profileService.currentRole())
          .thenAnswer((_) async => UserRole.ALTERNANT);
      when(() => matchingService.getSuggestions())
          .thenAnswer((_) async => [buildSuggestion('owner-1')]);
      await viewModel.loadExtras();
    }

    test('annonceur matché : réutilise le fil par personne, sans logementId',
        () async {
      await chargerAvecMatch();

      await viewModel.contacter();

      // La discussion porte sur l'arrangement, pas sur cette annonce :
      // sans ça on ouvrait un SECOND fil avec la même personne
      final capture = verify(() => navigationService.navigateTo(
          any(), arguments: captureAny(named: 'arguments'))).captured.last;
      final args = capture as ChatViewArguments;
      expect(args.conversation.logementId, isNull);
      expect(args.conversation.partnerId, 'owner-1');
    });

    test('annonceur matché : aucune candidature consultée ni créée', () async {
      await chargerAvecMatch();
      clearInteractions(candidatureService);

      await viewModel.contacter();

      // Le suivi est déjà porté par Matches — rien à faire côté candidatures
      verifyNever(() => candidatureService.getMesCandidatures());
      verifyNever(() => candidatureService.suivre(
            logementId: any(named: 'logementId'),
            statut: any(named: 'statut'),
          ));
    });

    test('annonceur non matché : fil rattaché à l\'annonce', () async {
      // Rôle étudiant par défaut → aucun match chargé
      await viewModel.loadExtras();

      await viewModel.contacter();

      final capture = verify(() => navigationService.navigateTo(
          any(), arguments: captureAny(named: 'arguments'))).captured.last;
      final args = capture as ChatViewArguments;
      expect(args.conversation.logementId, 'log-1');
    });
  });

  group('loadExtras', () {
    test('les extras échouent : non bloquant, pas d\'exception', () async {
      await viewModel.loadExtras(); // ne doit pas lever

      expect(viewModel.isBusy, isFalse);
    });
  });
}
