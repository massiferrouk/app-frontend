import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart' as stacked_services;
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/logements/mes_logements_viewmodel.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/profile_service.dart';
import 'package:studup_app/shared/models/alternant_profile.dart';
import 'package:studup_app/shared/models/enums.dart';
import 'package:studup_app/shared/models/logement.dart';

class MockLogementService extends Mock implements LogementService {}

class MockProfileService extends Mock implements ProfileService {}

class MockNavigationService extends Mock
    implements stacked_services.NavigationService {}

void main() {
  late MockLogementService logementService;
  late MockProfileService profileService;
  late MesLogementsViewModel viewModel;

  Logement build({LogementStatut statut = LogementStatut.BROUILLON}) =>
      Logement.fromJson({
        'id': 'log-1',
        'ownerId': 'user-1',
        'adresse': '12 rue de la Paix',
        'ville': 'Paris',
        'codePostal': '75001',
        'type': 'STUDIO',
        'surface': 25.0,
        'nbPieces': 1,
        'loyer': 800.0,
        'charges': 50.0,
        'description': 'Beau studio',
        'equipements': ['wifi'],
        'statut': statut.toJson(),
        'isVerified': false,
        'isMeuble': true,
        'villeAssociee': null,
        'photoUrls': [],
      });

  setUpAll(() => registerFallbackValue(VilleAssociee.VILLE_A));

  setUp(() {
    logementService = MockLogementService();
    profileService = MockProfileService();
    viewModel = MesLogementsViewModel(
      logementService: logementService,
      profileService: profileService,
      navigationService: MockNavigationService(),
    );
    when(() => profileService.currentRole())
        .thenAnswer((_) async => UserRole.ALTERNANT);
    // Profil chargé pour afficher les vrais noms de villes à l'association
    when(() => profileService.getMyAlternantProfile())
        .thenAnswer((_) async => null);
  });

  group('load', () {
    test('charge les logements et détecte le rôle alternant', () async {
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => [build()]);

      await viewModel.load();

      expect(viewModel.logements, hasLength(1));
      expect(viewModel.isAlternant, isTrue);
      expect(viewModel.logements.first.statut, LogementStatut.BROUILLON);
    });

    test('alternant : expose les deux villes du profil', () async {
      // La fiche s'en sert pour dire POURQUOI un logement publié reste hors
      // matching : ville étrangère au profil, ou ville déjà rattachée.
      when(() => profileService.getMyAlternantProfile()).thenAnswer(
        (_) async => AlternantProfile(
          id: 'p1',
          userId: 'u1',
          villeA: 'Bordeaux',
          villeB: 'Paris',
          ecole: 'YNOV',
          entreprise: 'ACME',
          dateDebut: DateTime(2026, 9, 1),
          dateFin: DateTime(2027, 8, 31),
          rythme: RythmeAlternance.SEMAINE_3_1,
          premiereSemaine: PremiereSemaine.ECOLE,
        ),
      );
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => [build()]);

      await viewModel.load();

      expect(viewModel.villeEcole, 'Bordeaux');
      expect(viewModel.villeEntreprise, 'Paris');
    });

    test('erreur API : message stocké', () async {
      when(() => logementService.getMesLogements())
          .thenThrow(const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur',
        statusCode: 0,
      ));

      await viewModel.load();

      expect(viewModel.logements, isEmpty);
      expect(viewModel.errorMessage, isNotNull);
    });
  });

  group('publish', () {
    test('succès : publie puis recharge', () async {
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => [build()]);
      await viewModel.load();

      when(() => logementService.publish('log-1')).thenAnswer(
          (_) async => build(statut: LogementStatut.ACTIF));

      final error = await viewModel.publish(viewModel.logements.first);

      expect(error, isNull);
      verify(() => logementService.getMesLogements()).called(2);
    });
  });

  group('supprimer', () {
    test('succès : supprime puis recharge', () async {
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => [build()]);
      await viewModel.load();

      when(() => logementService.delete('log-1')).thenAnswer((_) async {});

      final error = await viewModel.supprimer(viewModel.logements.first);

      expect(error, isNull);
      verify(() => logementService.delete('log-1')).called(1);
      verify(() => logementService.getMesLogements()).called(2);
    });

    test('409 : message clair quand un accord est lié', () async {
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => [build()]);
      await viewModel.load();

      when(() => logementService.delete(any())).thenThrow(const ApiException(
        code: 'CONFLICT',
        message: 'Conflit',
        statusCode: 409,
      ));

      final error = await viewModel.supprimer(viewModel.logements.first);

      expect(error, contains('accord'));
    });
  });
}
