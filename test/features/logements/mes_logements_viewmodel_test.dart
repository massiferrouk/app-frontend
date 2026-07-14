import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart' as stacked_services;
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/logements/mes_logements_viewmodel.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/services/profile_service.dart';
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

  group('associer', () {
    test('409 : message métier clair sur ville déjà occupée', () async {
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => [build()]);
      await viewModel.load();

      when(() => logementService.associerVille(any(), any()))
          .thenThrow(const ApiException(
        code: 'CONFLICT',
        message: 'Conflit',
        statusCode: 409,
      ));

      final error = await viewModel.associer(
          viewModel.logements.first, VilleAssociee.VILLE_A);

      expect(error, 'Tu as déjà un logement associé à cette ville');
    });

    test('succès : associe puis recharge', () async {
      when(() => logementService.getMesLogements())
          .thenAnswer((_) async => [build()]);
      await viewModel.load();

      when(() => logementService.associerVille('log-1', VilleAssociee.VILLE_B))
          .thenAnswer((_) async => build());

      final error = await viewModel.associer(
          viewModel.logements.first, VilleAssociee.VILLE_B);

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
