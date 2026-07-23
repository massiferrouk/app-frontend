import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/services/logement_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late LogementService service;

  const logementJson = {
    'id': 'l1',
    'ownerId': 'u1',
    'adresse': '1 rue de la Paix',
    'ville': 'Paris',
    'codePostal': '75001',
    'type': 'STUDIO',
    'surface': 25.0,
    'nbPieces': 1,
    'loyer': 700.0,
    'charges': 50.0,
    'statut': 'ACTIF',
    'isMeuble': true,
  };

  setUp(() {
    api = MockApiClient();
    service = LogementService(apiClient: api);
  });

  group('lectures', () {
    test('getMesLogements parse la liste', () async {
      when(() => api.get<List<dynamic>>('/logements/mes-logements'))
          .thenAnswer((_) async => [logementJson]);

      final result = await service.getMesLogements();

      expect(result, hasLength(1));
      expect(result.first.ville, 'Paris');
      expect(result.first.type, LogementType.STUDIO);
    });

    test('search extrait content + hasNext et transmet les filtres', () async {
      when(() => api.get<Map<String, dynamic>>('/logements',
          queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => {
          'content': [logementJson],
          'hasNext': true,
        },
      );

      final result = await service.search(ville: 'Paris', loyerMax: 800, page: 2);

      expect(result.logements, hasLength(1));
      expect(result.hasNext, isTrue);
      final qp = verify(() => api.get<Map<String, dynamic>>('/logements',
              queryParameters: captureAny(named: 'queryParameters')))
          .captured
          .single as Map<String, dynamic>;
      expect(qp['ville'], 'Paris');
      expect(qp['loyer_max'], 800);
      expect(qp['page'], 2);
    });

    test('getLogement parse le détail', () async {
      when(() => api.get<Map<String, dynamic>>('/logements/l1'))
          .thenAnswer((_) async => logementJson);

      expect((await service.getLogement('l1')).id, 'l1');
    });

    test('getDisponibilites parse la liste', () async {
      when(() => api.get<List<dynamic>>('/logements/l1/disponibilites'))
          .thenAnswer((_) async => [
                {
                  'id': 'd1',
                  'logementId': 'l1',
                  'dateDebut': '2026-09-01',
                  'dateFin': '2026-09-30',
                  'type': 'LIBRE',
                }
              ]);

      final result = await service.getDisponibilites('l1');
      expect(result.first.type, DisponibiliteType.LIBRE);
    });

    test('autocompleteAddress transmet la requête', () async {
      when(() => api.get<List<dynamic>>('/geocoding/autocomplete',
          queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => [
          {'label': '1 rue X, Paris', 'ville': 'Paris'}
        ],
      );

      final result = await service.autocompleteAddress('1 rue');
      expect(result.first.ville, 'Paris');
    });
  });

  group('écritures', () {
    test('createLogement envoie tous les champs', () async {
      when(() => api.post<Map<String, dynamic>>('/logements',
          data: any(named: 'data'))).thenAnswer((_) async => logementJson);

      await service.createLogement(
        adresse: '1 rue de la Paix',
        ville: 'Paris',
        codePostal: '75001',
        type: LogementType.STUDIO,
        surface: 25,
        nbPieces: 1,
        loyer: 700,
        charges: 50,
        isMeuble: true,
      );

      final sent = verify(() => api.post<Map<String, dynamic>>('/logements',
              data: captureAny(named: 'data')))
          .captured
          .single as Map<String, dynamic>;
      expect(sent['ville'], 'Paris');
      expect(sent['type'], 'STUDIO');
      expect(sent['isMeuble'], true);
    });

    test('updateLogement appelle PUT /logements/{id}', () async {
      when(() => api.put<Map<String, dynamic>>('/logements/l1',
          data: any(named: 'data'))).thenAnswer((_) async => logementJson);

      await service.updateLogement(
        logementId: 'l1',
        adresse: '1 rue',
        ville: 'Paris',
        codePostal: '75001',
        type: LogementType.STUDIO,
        surface: 25,
        nbPieces: 1,
        loyer: 700,
        charges: 50,
        isMeuble: true,
      );

      verify(() => api.put<Map<String, dynamic>>('/logements/l1',
          data: any(named: 'data'))).called(1);
    });

    test('publish appelle PUT /logements/{id}/publish', () async {
      when(() => api.put<Map<String, dynamic>>('/logements/l1/publish'))
          .thenAnswer((_) async => logementJson);

      await service.publish('l1');

      verify(() => api.put<Map<String, dynamic>>('/logements/l1/publish'))
          .called(1);
    });

    test('delete appelle DELETE et propage un conflit 409', () async {
      when(() => api.delete<void>('/logements/l1')).thenThrow(const ApiException(
          code: 'CONFLICT', message: 'Engagé', statusCode: 409));

      expect(service.delete('l1'), throwsA(isA<ApiException>()));
    });
  });
  group('signalement (APP-121)', () {
    test('reportLogement poste le motif', () async {
      when(() => api.post<Map<String, dynamic>>('/logements/l1/report',
          data: any(named: 'data'))).thenAnswer((_) async => {});

      await service.reportLogement('l1', 'Annonce frauduleuse');

      final envoye = verify(() => api.post<Map<String, dynamic>>(
                  '/logements/l1/report',
                  data: captureAny(named: 'data')))
              .captured
              .single as Map<String, dynamic>;
      // Obligatoire côté serveur : sans motif, 400
      expect(envoye['motif'], 'Annonce frauduleuse');
    });
  });
}
