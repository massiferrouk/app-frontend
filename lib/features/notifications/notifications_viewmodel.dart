import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/notification_service.dart';
import '../../shared/models/app_notification.dart';

/// Logique de l'écran notifications.
class NotificationsViewModel extends BaseViewModel {
  final NotificationService _notifications;

  NotificationsViewModel({NotificationService? notificationService})
      : _notifications =
            notificationService ?? locator<NotificationService>();

  List<AppNotification> notifications = [];
  String? errorMessage;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    setBusy(true);
    try {
      notifications = await _notifications.getNotifications();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Marque comme lue au tap. Optimiste : l'UI change tout de suite,
  /// l'appel part en arrière-plan (une notification lue deux fois
  /// n'a aucune conséquence).
  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    final index = notifications.indexOf(notification);
    if (index == -1) return;

    notifications[index] = AppNotification(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      isRead: true,
      deepLink: notification.deepLink,
      createdAt: notification.createdAt,
    );
    notifyListeners();

    try {
      await _notifications.markAsRead(notification.id);
    } on ApiException {
      // Silencieux : au pire elle réapparaîtra non lue au prochain refresh
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notifications.markAllAsRead();
      await load();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }
}
