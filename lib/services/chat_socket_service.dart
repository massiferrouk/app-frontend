import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/api/api_config.dart';
import '../shared/models/app_notification.dart';
import '../shared/models/message.dart';

/// Client WebSocket STOMP temps réel — messagerie ET notifications.
///
/// Le backend broadcast (via SimpMessagingTemplate) sur trois familles de
/// destinations :
/// - /topic/conversation/{id}           : messages d'un chat ouvert
/// - /topic/user/{userId}/messages       : tout message reçu (badge Messages, APP-102)
/// - /topic/user/{userId}/notifications  : toute notification (badge Alertes + bannière, APP-122)
///
/// Ce service maintient UNE connexion partagée et des abonnements par
/// destination, réabonnés automatiquement après une reconnexion.
///
/// SockJS (pas WebSocket brut) : c'est ce que le backend expose, avec fallback
/// automatique si un proxy bloque les WebSockets.
class ChatSocketService {
  StompClient? _client;
  bool _stompConnected = false;

  /// Callbacks actifs par destination STOMP — resouscrits après reconnexion.
  /// Le payload est passé décodé en JSON brut ; chaque abonnement PUBLIC le
  /// convertit ensuite vers son type métier (ChatMessage, AppNotification…).
  /// C'est ce qui permet à un seul canal de porter plusieurs types de messages.
  final Map<String, void Function(Map<String, dynamic>)> _callbacks = {};

  /// Fonctions de désabonnement STOMP par destination
  final Map<String, dynamic> _unsubscribers = {};

  void _ensureConnected() {
    if (_client != null) return;

    _client = StompClient(
      config: StompConfig.sockJS(
        url: ApiConfig.wsUrl,
        onConnect: _onConnect,
        onDisconnect: (_) => _stompConnected = false,
        // Reconnexion automatique : coupure réseau, backend redémarré...
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 30),
        heartbeatIncoming: const Duration(seconds: 30),
      ),
    )..activate();
  }

  void _onConnect(StompFrame frame) {
    _stompConnected = true;
    // Après (re)connexion : réabonne toutes les destinations actives
    for (final entry in _callbacks.entries) {
      _doSubscribe(entry.key, entry.value);
    }
  }

  void _doSubscribe(
      String destination, void Function(Map<String, dynamic>) onJson) {
    final unsubscribe = _client!.subscribe(
      destination: destination,
      callback: (frame) {
        if (frame.body == null) return;
        try {
          onJson(jsonDecode(frame.body!) as Map<String, dynamic>);
        } catch (_) {
          // Payload inattendu : on ignore plutôt que de crasher l'abonnement
        }
      },
    );
    _unsubscribers[destination] = unsubscribe;
  }

  void _subscribe(
      String destination, void Function(Map<String, dynamic>) onJson) {
    _callbacks[destination] = onJson;
    _ensureConnected();
    if (_stompConnected) _doSubscribe(destination, onJson);
  }

  void _unsubscribe(String destination) {
    _callbacks.remove(destination);
    final unsubscribe = _unsubscribers.remove(destination);
    if (unsubscribe != null && _stompConnected) {
      unsubscribe();
    }
  }

  // ─── Messagerie ────────────────────────────────────────────────────────────

  /// S'abonne aux messages temps réel d'une conversation.
  void subscribeToConversation(
          String conversationId, void Function(ChatMessage) onMessage) =>
      _subscribe('/topic/conversation/$conversationId',
          (json) => onMessage(ChatMessage.fromJson(json)));

  /// Se désabonne (appelé quand on quitte l'écran de chat).
  void unsubscribeFromConversation(String conversationId) =>
      _unsubscribe('/topic/conversation/$conversationId');

  /// S'abonne au topic personnel : reçoit TOUT message qui m'est adressé,
  /// quel que soit l'écran ouvert — alimente le badge Messages (APP-102).
  void subscribeToUserMessages(
          String userId, void Function(ChatMessage) onMessage) =>
      _subscribe('/topic/user/$userId/messages',
          (json) => onMessage(ChatMessage.fromJson(json)));

  void unsubscribeFromUserMessages(String userId) =>
      _unsubscribe('/topic/user/$userId/messages');

  // ─── Notifications (APP-122) ────────────────────────────────────────────────

  /// S'abonne au topic personnel des notifications : reçoit TOUTE notification
  /// qui m'est destinée (annonce suivie, nouveau match…), quel que soit l'écran
  /// ouvert. Alimente le badge Alertes en temps réel et déclenche la bannière.
  void subscribeToUserNotifications(
          String userId, void Function(AppNotification) onNotification) =>
      _subscribe('/topic/user/$userId/notifications',
          (json) => onNotification(AppNotification.fromJson(json)));

  void unsubscribeFromUserNotifications(String userId) =>
      _unsubscribe('/topic/user/$userId/notifications');

  // ─── Cycle de vie ────────────────────────────────────────────────────────────

  /// Coupe la connexion (logout).
  void disconnect() {
    _callbacks.clear();
    _unsubscribers.clear();
    _client?.deactivate();
    _client = null;
    _stompConnected = false;
  }
}
