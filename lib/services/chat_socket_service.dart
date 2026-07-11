import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../core/api/api_config.dart';
import '../shared/models/message.dart';

/// Client WebSocket STOMP de la messagerie temps réel.
///
/// Le backend broadcast chaque message sur /topic/conversation/{id}
/// (cf. MessageService.sendMessage côté Spring). Ce service maintient
/// UNE connexion partagée et des abonnements par conversation.
///
/// SockJS (pas WebSocket brut) : c'est ce que le backend expose,
/// avec fallback automatique si un proxy bloque les WebSockets.
class ChatSocketService {
  StompClient? _client;
  bool _stompConnected = false;

  /// Callbacks actifs par conversation — resouscrits après reconnexion
  final Map<String, void Function(ChatMessage)> _callbacks = {};

  /// Fonctions de désabonnement STOMP par conversation
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
    // Après (re)connexion : réabonne toutes les conversations actives
    for (final entry in _callbacks.entries) {
      _doSubscribe(entry.key, entry.value);
    }
  }

  void _doSubscribe(
      String conversationId, void Function(ChatMessage) onMessage) {
    final unsubscribe = _client!.subscribe(
      destination: '/topic/conversation/$conversationId',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          onMessage(ChatMessage.fromJson(
              jsonDecode(frame.body!) as Map<String, dynamic>));
        } catch (_) {
          // Payload inattendu : on ignore plutôt que de crasher le chat
        }
      },
    );
    _unsubscribers[conversationId] = unsubscribe;
  }

  /// S'abonne aux messages temps réel d'une conversation.
  void subscribeToConversation(
      String conversationId, void Function(ChatMessage) onMessage) {
    _callbacks[conversationId] = onMessage;
    _ensureConnected();
    if (_stompConnected) _doSubscribe(conversationId, onMessage);
  }

  /// Se désabonne (appelé quand on quitte l'écran de chat).
  void unsubscribeFromConversation(String conversationId) {
    _callbacks.remove(conversationId);
    final unsubscribe = _unsubscribers.remove(conversationId);
    if (unsubscribe != null && _stompConnected) {
      unsubscribe();
    }
  }

  /// Coupe la connexion (logout).
  void disconnect() {
    _callbacks.clear();
    _unsubscribers.clear();
    _client?.deactivate();
    _client = null;
    _stompConnected = false;
  }
}
