import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/services/accord_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late AccordService service;

  const accordJson = {
    'id': 'a1',
    'initiatorId': 'u1',
    'receiverId': 'u2',
    'type': 'ECHANGE_TOTAL',
    'statut': 'EN_ATTENTE',
    'dateDebut': '2026-09-01',
    'dateFin': '2027-08-31',
    'createdAt': '2026-07-18T10:00:00Z',
  };

  setUp(() {
    api = MockApiClient();
    service = AccordService(apiClient: api);
  });

  group('getMesAccords', () {
    test('extrait le champ content de la Page Spring', () async {
      when(() => api.get<Map<String, dynamic>>('/accords/mes-accords'))
          .thenAnswer((_) async => {
                'content': [accordJson]
              });

      final result = await service.getMesAccords();

      expect(result, hasLength(1));
      expect(result.first.id, 'a1');
      expect(result.first.type, AccordType.ECHANGE_TOTAL);
    });

    test('content absent → liste vide (pas de crash)', () async {
      when(() => api.get<Map<String, dynamic>>('/accords/mes-accords'))
          .thenAnswer((_) async => {});

      expect(await service.getMesAccords(), isEmpty);
    });
  });

  group('createAccord', () {
    test('envoie le bon corps et parse la réponse', () async {
      when(() => api.post<Map<String, dynamic>>('/accords',
          data: any(named: 'data'))).thenAnswer((_) async => accordJson);

      final accord = await service.createAccord(
        receiverId: 'u2',
        type: AccordType.ECHANGE_TOTAL,
        logementAId: 'lA',
        logementBId: 'lB',
        messageInitial: 'Salut',
      );

      expect(accord.id, 'a1');
      final sent = verify(() => api.post<Map<String, dynamic>>('/accords',
              data: captureAny(named: 'data')))
          .captured
          .single as Map<String, dynamic>;
      expect(sent['receiverId'], 'u2');
      expect(sent['type'], 'ECHANGE_TOTAL');
      expect(sent['logementAId'], 'lA');
      expect(sent['messageInitial'], 'Salut');
    });
  });

  group('actions accept/refuse/cancel', () {
    test('accept appelle PUT /accords/{id}/accept', () async {
      when(() => api.put<Map<String, dynamic>>('/accords/a1/accept'))
          .thenAnswer((_) async => accordJson);

      await service.accept('a1');

      verify(() => api.put<Map<String, dynamic>>('/accords/a1/accept'))
          .called(1);
    });

    test('refuse appelle PUT /accords/{id}/refuse', () async {
      when(() => api.put<Map<String, dynamic>>('/accords/a1/refuse'))
          .thenAnswer((_) async => accordJson);

      await service.refuse('a1');

      verify(() => api.put<Map<String, dynamic>>('/accords/a1/refuse'))
          .called(1);
    });

    test('cancel appelle PUT /accords/{id}/cancel', () async {
      when(() => api.put<Map<String, dynamic>>('/accords/a1/cancel'))
          .thenAnswer((_) async => accordJson);

      await service.cancel('a1');

      verify(() => api.put<Map<String, dynamic>>('/accords/a1/cancel'))
          .called(1);
    });

    test('getAccord propage une ApiException 404', () async {
      when(() => api.get<Map<String, dynamic>>('/accords/inconnu')).thenThrow(
          const ApiException(
              code: 'NOT_FOUND', message: 'Introuvable', statusCode: 404));

      expect(service.getAccord('inconnu'), throwsA(isA<ApiException>()));
    });
  });
}
