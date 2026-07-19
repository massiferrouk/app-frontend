import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/chat_socket_service.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/message.dart';

/// Logique de l'écran de chat.
class ChatViewModel extends BaseViewModel {
  final MessageService _messages;
  final ProfileService _profile;
  final ChatSocketService _socket;
  final ConversationSummary conversation;

  ChatViewModel({
    required this.conversation,
    MessageService? messageService,
    ProfileService? profileService,
    ChatSocketService? chatSocketService,
  })  : _messages = messageService ?? locator<MessageService>(),
        _profile = profileService ?? locator<ProfileService>(),
        _socket = chatSocketService ?? locator<ChatSocketService>();

  /// Conversation à laquelle on est abonné en temps réel
  String? _subscribedConversationId;

  /// Id de conversation effectif. Vide à l'ouverture via « Contacter » ;
  /// résolu depuis le partenaire si une conversation existe déjà (A-02).
  String _conversationId = '';

  final inputController = TextEditingController();

  /// Vrai tant que `init()` n'a pas fini (résolution + chargement historique).
  /// Évite de faire clignoter l'état vide « Dis bonjour » avant l'historique.
  bool initializing = true;

  /// Messages du plus ancien au plus récent (ordre d'affichage du chat)
  List<ChatMessage> messages = [];
  String? currentUserId;
  String? errorMessage;
  bool sending = false;

  bool isMine(ChatMessage m) => m.senderId == currentUserId;

  Future<void> init() async {
    currentUserId = await _profile.currentUserId();
    _conversationId = conversation.conversationId;
    await _resolveExistingConversation();
    await load();
    initializing = false;
    notifyListeners();
    _markUnreadAsRead();
    _subscribeIfPossible(_conversationId);
  }

  /// Ouverture via « Contacter » (id vide) : si une conversation existe déjà
  /// avec ce partenaire, on la retrouve pour charger son historique au lieu
  /// d'afficher un chat vide « Dites bonjour à… » (anomalie A-02).
  Future<void> _resolveExistingConversation() async {
    if (_conversationId.isNotEmpty || conversation.partnerId == null) return;
    try {
      final convs = await _messages.getConversations();
      for (final c in convs) {
        if (c.partnerId == conversation.partnerId) {
          _conversationId = c.conversationId;
          break;
        }
      }
    } on ApiException {
      // silencieux : on démarre alors une nouvelle conversation
    }
  }

  /// Abonnement temps réel — dès qu'on connaît l'id de la conversation
  void _subscribeIfPossible(String conversationId) {
    if (conversationId.isEmpty ||
        _subscribedConversationId == conversationId) {
      return;
    }
    _subscribedConversationId = conversationId;
    _socket.subscribeToConversation(conversationId, onMessageReceived);
  }

  Future<void> load() async {
    // Vraiment nouvelle conversation (aucune existante avec ce partenaire) :
    // pas encore d'historique. Elle sera créée au premier message envoyé.
    if (_conversationId.isEmpty) return;

    setBusy(true);
    try {
      // Le backend renvoie du plus récent au plus ancien : on inverse
      final history = await _messages.getHistory(_conversationId);
      messages = history.reversed.toList();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      setBusy(false);
    }
  }

  /// Marque les messages reçus non lus — en arrière-plan, sans bloquer
  Future<void> _markUnreadAsRead() async {
    final unread = messages
        .where((m) => !m.isRead && !isMine(m))
        .toList();
    for (final m in unread) {
      try {
        await _messages.markAsRead(m.id);
      } on ApiException {
        // silencieux
      }
    }
  }

  Future<void> send() async {
    final content = inputController.text.trim();
    if (content.isEmpty || sending) return;
    if (conversation.partnerId == null) return;

    sending = true;
    notifyListeners();
    try {
      final sent =
          await _messages.sendMessage(conversation.partnerId!, content);
      // Le broadcast WebSocket arrive souvent AVANT cette réponse REST :
      // le message est alors déjà dans la liste (via onMessageReceived).
      // Sans ce garde, l'émetteur voyait son message en double.
      if (!messages.any((m) => m.id == sent.id)) {
        messages.add(sent);
      }
      inputController.clear();
      errorMessage = null;
      // Nouvelle conversation : le backend vient de la créer,
      // on retient son id et on s'abonne au temps réel
      _conversationId = sent.conversationId;
      _subscribeIfPossible(sent.conversationId);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  /// Injecte un message reçu en temps réel (WebSocket — étape 3).
  /// Ignore les doublons (le message envoyé revient aussi par le broadcast).
  void onMessageReceived(ChatMessage message) {
    if (messages.any((m) => m.id == message.id)) return;
    messages.add(message);
    notifyListeners();
    if (!isMine(message)) {
      _messages.markAsRead(message.id).catchError((_) {});
    }
  }

  @override
  void dispose() {
    if (_subscribedConversationId != null) {
      _socket.unsubscribeFromConversation(_subscribedConversationId!);
    }
    inputController.dispose();
    super.dispose();
  }
}
