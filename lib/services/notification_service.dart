import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/app_notification.dart';

/// Service des notifications in-app.
class NotificationService {
  final ApiClient _api;

  NotificationService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// GET /notifications — Page Spring, on extrait content
  Future<List<AppNotification>> getNotifications() async {
    final data = await _api.get<Map<String, dynamic>>('/notifications');
    return (data['content'] as List? ?? [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /notifications/unread-count → {"count": n}
  Future<int> getUnreadCount() async {
    final data =
        await _api.get<Map<String, dynamic>>('/notifications/unread-count');
    return (data['count'] as num? ?? 0).toInt();
  }

  Future<void> markAsRead(String id) =>
      _api.patch<dynamic>('/notifications/$id/read');

  Future<void> markAllAsRead() =>
      _api.patch<dynamic>('/notifications/read-all');
}
