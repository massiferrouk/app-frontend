import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studup_app/core/api/api_exception.dart';
import 'package:studup_app/features/notifications/notifications_viewmodel.dart';
import 'package:studup_app/services/notification_service.dart';
import 'package:studup_app/shared/models/app_notification.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockNotificationService service;
  late NotificationsViewModel viewModel;

  AppNotification build({required String id, bool isRead = false}) =>
      AppNotification.fromJson({
        'id': id,
        'type': 'NOUVEAU_MATCH',
        'title': 'Nouveau match !',
        'body': 'Thomas D. est compatible à 87%',
        'isRead': isRead,
        'deepLink': null,
        'createdAt': DateTime.now().toIso8601String(),
      });

  setUp(() {
    service = MockNotificationService();
    viewModel = NotificationsViewModel(notificationService: service);
  });

  group('load', () {
    test('charge et compte les non lues', () async {
      when(() => service.getNotifications()).thenAnswer((_) async => [
            build(id: 'n1'),
            build(id: 'n2', isRead: true),
            build(id: 'n3'),
          ]);

      await viewModel.load();

      expect(viewModel.notifications, hasLength(3));
      expect(viewModel.unreadCount, 2);
    });

    test('erreur API : message stocké', () async {
      when(() => service.getNotifications()).thenThrow(const ApiException(
          code: 'NETWORK_ERROR', message: 'Hors ligne', statusCode: 0));

      await viewModel.load();

      expect(viewModel.errorMessage, 'Hors ligne');
    });
  });

  group('markAsRead', () {
    test('optimiste : l\'UI change avant la réponse serveur', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1')]);
      when(() => service.markAsRead('n1')).thenAnswer((_) async {});

      await viewModel.load();
      expect(viewModel.unreadCount, 1);

      await viewModel.markAsRead(viewModel.notifications.first);

      expect(viewModel.unreadCount, 0);
      verify(() => service.markAsRead('n1')).called(1);
    });

    test('déjà lue : aucun appel', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1', isRead: true)]);
      await viewModel.load();

      await viewModel.markAsRead(viewModel.notifications.first);

      verifyNever(() => service.markAsRead(any()));
    });

    test('échec serveur silencieux : l\'UI reste marquée lue', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1')]);
      when(() => service.markAsRead('n1')).thenThrow(const ApiException(
          code: 'ERROR', message: 'Erreur', statusCode: 500));
      await viewModel.load();

      await viewModel.markAsRead(viewModel.notifications.first);

      expect(viewModel.unreadCount, 0); // pas de rollback, pas de crash
    });
  });

  group('markAllAsRead', () {
    test('appelle le serveur puis recharge', () async {
      when(() => service.getNotifications())
          .thenAnswer((_) async => [build(id: 'n1')]);
      when(() => service.markAllAsRead()).thenAnswer((_) async {});
      await viewModel.load();

      await viewModel.markAllAsRead();

      verify(() => service.markAllAsRead()).called(1);
      verify(() => service.getNotifications()).called(2);
    });
  });
}
