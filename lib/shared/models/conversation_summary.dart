import 'enums.dart';

/// Miroir du ConversationSummaryResponse backend — une ligne de la
/// liste des conversations.
class ConversationSummary {
  final String conversationId;
  final String? partnerId;
  final String partnerName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Annonce sur laquelle porte la discussion (APP-119).
  /// null = discussion de personne à personne (mise en relation alternant).
  /// Deux annonces du même propriétaire = deux conversations distinctes.
  final String? logementId;
  final String? logementVille;
  final LogementType? logementType;

  const ConversationSummary({
    required this.conversationId,
    this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.logementId,
    this.logementVille,
    this.logementType,
  });

  /// Libellé court de l'annonce, ex. « Studio · Bordeaux » — null si la
  /// discussion ne porte pas sur un logement.
  String? get logementLabel {
    if (logementId == null) return null;
    final ville = logementVille;
    final type = logementType?.label;
    if (ville == null) return type;
    return type == null ? ville : '$type · $ville';
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final type = json['logementType'] as String?;
    return ConversationSummary(
      conversationId: json['conversationId'] as String,
      partnerId: json['partnerId'] as String?,
      partnerName: json['partnerName'] as String? ?? 'Utilisateur',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: (json['unreadCount'] as num? ?? 0).toInt(),
      logementId: json['logementId'] as String?,
      logementVille: json['logementVille'] as String?,
      // Valeur inconnue (enum ajouté côté backend) : on dégrade sans planter
      logementType: type == null ? null : _typeOrNull(type),
    );
  }

  static LogementType? _typeOrNull(String value) {
    try {
      return LogementType.fromJson(value);
    } on ArgumentError {
      return null;
    }
  }
}
