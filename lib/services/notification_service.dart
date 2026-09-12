import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/app_notification.dart';

/// Service des notifications in-app.
class NotificationService {
  final ApiClient _api;

  NotificationService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// Dernière liste de notifications récupérée (APP-122) — voir le même
  /// mécanisme sur MessageService : permet le stale-while-revalidate de
  /// l'onglet Alertes (afficher tout de suite, rafraîchir en fond).
  List<AppNotification>? cachedNotifications;

  /// GET /notifications — Page Spring, on extrait content
  Future<List<AppNotification>> getNotifications() async {
    final data = await _api.get<Map<String, dynamic>>('/notifications');
    final notifications = (data['content'] as List? ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    cachedNotifications = notifications;
    return notifications;
  }

  /// GET /notifications/unread-count → {"unreadCount": n}
  Future<int> getUnreadCount() async {
    final data =
        await _api.get<Map<String, dynamic>>('/notifications/unread-count');
    return (data['unreadCount'] as num? ?? 0).toInt();
  }

  Future<void> markAsRead(String id) =>
      _api.patch<dynamic>('/notifications/$id/read');

  Future<void> markAllAsRead() =>
      _api.patch<dynamic>('/notifications/read-all');
}
