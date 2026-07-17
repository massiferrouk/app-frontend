import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_client.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/shared/models/enums.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late NotificationService service;

  const notifJson = {
    'id': 'n1',
    'type': 'NOUVEAU_MATCH',
    'title': 'Nouveau match',
    'body': 'Un alternant compatible',
    'isRead': false,
    'createdAt': '2026-07-18T10:00:00Z',
  };

  setUp(() {
    api = MockApiClient();
    service = NotificationService(apiClient: api);
  });

  test('getNotifications extrait content et parse le type', () async {
    when(() => api.get<Map<String, dynamic>>('/notifications'))
        .thenAnswer((_) async => {
              'content': [notifJson]
            });

    final result = await service.getNotifications();

    expect(result, hasLength(1));
    expect(result.first.type, NotificationType.NOUVEAU_MATCH);
    expect(result.first.isRead, isFalse);
  });

  test('getUnreadCount lit le champ unreadCount', () async {
    when(() => api.get<Map<String, dynamic>>('/notifications/unread-count'))
        .thenAnswer((_) async => {'unreadCount': 3});

    expect(await service.getUnreadCount(), 3);
  });

  test('getUnreadCount → 0 si le champ est absent', () async {
    when(() => api.get<Map<String, dynamic>>('/notifications/unread-count'))
        .thenAnswer((_) async => {});

    expect(await service.getUnreadCount(), 0);
  });

  test('markAsRead appelle PATCH /notifications/{id}/read', () async {
    when(() => api.patch<dynamic>('/notifications/n1/read'))
        .thenAnswer((_) async => null);

    await service.markAsRead('n1');

    verify(() => api.patch<dynamic>('/notifications/n1/read')).called(1);
  });

  test('markAllAsRead appelle PATCH /notifications/read-all', () async {
    when(() => api.patch<dynamic>('/notifications/read-all'))
        .thenAnswer((_) async => null);

    await service.markAllAsRead();

    verify(() => api.patch<dynamic>('/notifications/read-all')).called(1);
  });
}
