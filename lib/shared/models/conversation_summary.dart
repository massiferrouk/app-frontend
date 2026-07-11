/// Miroir du ConversationSummaryResponse backend — une ligne de la
/// liste des conversations.
class ConversationSummary {
  final String conversationId;
  final String? partnerId;
  final String partnerName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationSummary({
    required this.conversationId,
    this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      conversationId: json['conversationId'] as String,
      partnerId: json['partnerId'] as String?,
      partnerName: json['partnerName'] as String? ?? 'Utilisateur',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: (json['unreadCount'] as num? ?? 0).toInt(),
    );
  }
}
