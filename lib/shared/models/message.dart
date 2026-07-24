/// Miroir du MessageResponse backend.
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  /// Masqué par la modération (APP-121). Le contenu reste transmis pour la
  /// traçabilité côté serveur, mais l'app remplace le texte par un libellé.
  final bool isHidden;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.isHidden = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }
}
