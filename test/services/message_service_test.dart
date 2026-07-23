import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/services/message_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late MessageService service;

  const messageJson = {
    'id': 'm1',
    'conversationId': 'c1',
    'senderId': 'u1',
    'content': 'Salut',
    'isRead': false,
    'createdAt': '2026-07-18T10:00:00Z',
  };

  setUp(() {
    api = MockApiClient();
    service = MessageService(apiClient: api);
  });

  test('getConversations parse la liste', () async {
    when(() => api.get<List<dynamic>>('/messages/conversations'))
        .thenAnswer((_) async => [
              {
                'conversationId': 'c1',
                'partnerId': 'u2',
                'partnerName': 'Félix',
                'lastMessage': 'Salut',
                'unreadCount': 2,
              }
            ]);

    final result = await service.getConversations();

    expect(result, hasLength(1));
    expect(result.first.partnerName, 'Félix');
    expect(result.first.unreadCount, 2);
  });

  test('getHistory extrait content (Page Spring)', () async {
    when(() => api.get<Map<String, dynamic>>('/messages/c1'))
        .thenAnswer((_) async => {
              'content': [messageJson]
            });

    final result = await service.getHistory('c1');

    expect(result, hasLength(1));
    expect(result.first.content, 'Salut');
  });

  test('sendMessage poste sur la bonne route et parse la réponse', () async {
    when(() => api.post<Map<String, dynamic>>('/messages/send/u2',
        data: any(named: 'data'))).thenAnswer((_) async => messageJson);

    final msg = await service.sendMessage('u2', 'Salut');

    expect(msg.content, 'Salut');
    final sent = verify(() => api.post<Map<String, dynamic>>(
            '/messages/send/u2',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(sent['content'], 'Salut');
  });

  test('markAsRead appelle PATCH /messages/{id}/read', () async {
    when(() => api.patch<dynamic>('/messages/m1/read'))
        .thenAnswer((_) async => null);

    await service.markAsRead('m1');

    verify(() => api.patch<dynamic>('/messages/m1/read')).called(1);
  });
  group('signalement (APP-121)', () {
    test('reportMessage poste le motif', () async {
      when(() => api.post<Map<String, dynamic>>('/messages/m1/report',
          data: any(named: 'data'))).thenAnswer((_) async => {});

      await service.reportMessage('m1', 'Propos insultants');

      final envoye = verify(() => api.post<Map<String, dynamic>>(
                  '/messages/m1/report',
                  data: captureAny(named: 'data')))
              .captured
              .single as Map<String, dynamic>;
      // Obligatoire côté serveur : sans motif, 400
      expect(envoye['motif'], 'Propos insultants');
    });
  });
}
