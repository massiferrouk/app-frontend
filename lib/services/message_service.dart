import '../app/app.locator.dart';
import '../core/api/api_client.dart';
import '../shared/models/conversation_summary.dart';
import '../shared/models/message.dart';

/// Service de la messagerie (partie REST).
/// Le temps réel WebSocket STOMP est géré par ChatSocketService.
class MessageService {
  final ApiClient _api;

  MessageService({ApiClient? apiClient})
      : _api = apiClient ?? locator<ApiClient>();

  /// Dernière liste de conversations récupérée (APP-122).
  /// Le service est un singleton, donc ce cache survit au remontage de l'écran
  /// Messages : la liste peut être réaffichée instantanément pendant qu'un
  /// rafraîchissement se fait en arrière-plan (stale-while-revalidate), au lieu
  /// de repartir d'un écran vide + spinner à chaque entrée sur l'onglet.
  List<ConversationSummary>? cachedConversations;

  /// GET /messages/conversations — mes conversations, triées par activité
  Future<List<ConversationSummary>> getConversations() async {
    final data =
        await _api.get<List<dynamic>>('/messages/conversations');
    final conversations = data
        .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    cachedConversations = conversations;
    return conversations;
  }

  /// GET /messages/{conversationId} — historique paginé
  /// (Page Spring : le backend renvoie les plus récents en premier)
  Future<List<ChatMessage>> getHistory(String conversationId) async {
    final data =
        await _api.get<Map<String, dynamic>>('/messages/$conversationId');
    return (data['content'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /messages/send/{receiverId} — envoi (persiste ET broadcast
  /// WebSocket côté backend).
  ///
  /// [logementId] : annonce concernée (APP-119). Le backend range le message
  /// dans le fil de CETTE annonce — un propriétaire avec plusieurs logements a
  /// un fil par bien. Laissé null pour une discussion de personne à personne.
  Future<ChatMessage> sendMessage(
    String receiverId,
    String content, {
    String? logementId,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/messages/send/$receiverId',
      data: {
        'content': content,
        // Omis du corps si null : le backend traite l'absence comme
        // « discussion de personne à personne »
        'logementId': ?logementId,
      },
    );
    return ChatMessage.fromJson(data);
  }

  /// PATCH /messages/{messageId}/read
  Future<void> markAsRead(String messageId) =>
      _api.patch<dynamic>('/messages/$messageId/read');

  /// POST /messages/{id}/report — signale un message à la modération.
  ///
  /// C'est le seul point d'entrée de la file de modération : sans lui, la
  /// table des signalements reste vide et l'écran admin n'affiche jamais rien
  /// (APP-121).
  ///
  /// Le motif est obligatoire côté serveur (400 si vide). Un 409 signifie que
  /// l'utilisateur a déjà signalé ce message — contrainte d'unicité en base.
  Future<void> reportMessage(String messageId, String motif) =>
      _api.post<Map<String, dynamic>>(
        '/messages/$messageId/report',
        data: {'motif': motif},
      );
}
