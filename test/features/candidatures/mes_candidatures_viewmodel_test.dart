import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/candidatures/mes_candidatures_viewmodel.dart';
import 'package:studup_app/services/candidature_service.dart';
import 'package:studup_app/shared/models/candidature.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockCandidatureService extends Mock implements CandidatureService {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  late MockCandidatureService candidatureService;
  late MesCandidaturesViewModel viewModel;

  Candidature candidature(String id, CandidatureStatut statut) =>
      Candidature.fromJson({
        'id': id,
        'statut': statut.toJson(),
        'note': null,
        'createdAt': '2026-07-01T10:00:00Z',
        'updatedAt': '2026-07-01T10:00:00Z',
        'logement': {
          'id': 'log-$id',
          'ownerId': 'o1',
          'adresse': '1 rue Test',
          'ville': 'Paris',
          'codePostal': '75001',
          'type': 'STUDIO',
          'statut': 'ACTIF',
        },
      });

  setUpAll(() {
    registerFallbackValue(CandidatureStatut.A_CONTACTER);
  });

  setUp(() {
    candidatureService = MockCandidatureService();
    viewModel = MesCandidaturesViewModel(
      candidatureService: candidatureService,
      navigationService: MockNavigationService(),
    );
  });

  group('load', () {
    test('charge les candidatures', () async {
      when(() => candidatureService.getMesCandidatures()).thenAnswer(
          (_) async => [candidature('c1', CandidatureStatut.CONTACTE)]);

      await viewModel.load();

      expect(viewModel.candidatures, hasLength(1));
      expect(viewModel.isEmpty, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('erreur API : message stocké, liste vide', () async {
      when(() => candidatureService.getMesCandidatures()).thenThrow(
          const ApiException(
              code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.load();

      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.errorMessage, 'Hors ligne');
    });
  });

  group('filtres', () {
    setUp(() {
      when(() => candidatureService.getMesCandidatures()).thenAnswer(
        (_) async => [
          candidature('c1', CandidatureStatut.CONTACTE),
          candidature('c2', CandidatureStatut.CONTACTE),
          candidature('c3', CandidatureStatut.VISITEE),
        ],
      );
    });

    test('countFor compte par statut', () async {
      await viewModel.load();

      expect(viewModel.countFor(CandidatureStatut.CONTACTE), 2);
      expect(viewModel.countFor(CandidatureStatut.VISITEE), 1);
      expect(viewModel.countFor(CandidatureStatut.SANS_SUITE), 0);
    });

    test('toggleFiltre filtre puis désactive au re-tap', () async {
      await viewModel.load();

      viewModel.toggleFiltre(CandidatureStatut.VISITEE);
      expect(viewModel.candidatures, hasLength(1));
      expect(viewModel.candidatures.first.id, 'c3');

      viewModel.toggleFiltre(CandidatureStatut.VISITEE);
      expect(viewModel.filtre, isNull);
      expect(viewModel.candidatures, hasLength(3));
    });
  });

  group('changerStatut', () {
    test('remplace l\'élément sans recharger toute la liste', () async {
      final avant = candidature('c1', CandidatureStatut.CONTACTE);
      when(() => candidatureService.getMesCandidatures())
          .thenAnswer((_) async => [avant]);
      await viewModel.load();

      when(() => candidatureService.updateStatut(
            candidatureId: any(named: 'candidatureId'),
            statut: any(named: 'statut'),
            note: any(named: 'note'),
          )).thenAnswer(
          (_) async => candidature('c1', CandidatureStatut.VISITE_PREVUE));

      final erreur =
          await viewModel.changerStatut(avant, CandidatureStatut.VISITE_PREVUE);

      expect(erreur, isNull);
      expect(viewModel.candidatures.first.statut,
          CandidatureStatut.VISITE_PREVUE);
      // Une seule lecture réseau : celle du load initial
      verify(() => candidatureService.getMesCandidatures()).called(1);
    });

    test('erreur API : message retourné, liste inchangée', () async {
      final avant = candidature('c1', CandidatureStatut.CONTACTE);
      when(() => candidatureService.getMesCandidatures())
          .thenAnswer((_) async => [avant]);
      await viewModel.load();

      when(() => candidatureService.updateStatut(
            candidatureId: any(named: 'candidatureId'),
            statut: any(named: 'statut'),
            note: any(named: 'note'),
          )).thenThrow(const ApiException(
          code: 'ERROR', message: 'Échec', statusCode: 500));

      final erreur =
          await viewModel.changerStatut(avant, CandidatureStatut.VISITEE);

      expect(erreur, 'Échec');
      expect(viewModel.candidatures.first.statut, CandidatureStatut.CONTACTE);
    });
  });

  group('retirer', () {
    test('enlève la candidature de la liste', () async {
      final c = candidature('c1', CandidatureStatut.SANS_SUITE);
      when(() => candidatureService.getMesCandidatures())
          .thenAnswer((_) async => [c]);
      await viewModel.load();

      when(() => candidatureService.delete('c1')).thenAnswer((_) async {});

      final erreur = await viewModel.retirer(c);

      expect(erreur, isNull);
      expect(viewModel.isEmpty, isTrue);
    });
  });
}
