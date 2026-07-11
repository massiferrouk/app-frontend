import 'enums.dart';

/// Miroir du NotificationResponse backend.
/// Nommé AppNotification : "Notification" existe déjà dans Flutter.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;

  /// Route interne cible (ex: "accord/123") — posée par le backend
  final String? deepLink;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.deepLink,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromJson(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      deepLink: json['deepLink'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
