import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../app/app.locator.dart';
import '../../core/api/api_exception.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import '../../shared/models/conversation_summary.dart';
import '../../shared/models/message.dart';

/// Logique de l'écran de chat.
class ChatViewModel extends BaseViewModel {
  final MessageService _messages;
  final ProfileService _profile;
  final ConversationSummary conversation;

  ChatViewModel({
    required this.conversation,
    MessageService? messageService,
    ProfileService? profileService,
  })  : _messages = messageService ?? locator<MessageService>(),
        _profile = profileService ?? locator<ProfileService>();

  final inputController = TextEditingController();

  /// Messages du plus ancien au plus récent (ordre d'affichage du chat)
  List<ChatMessage> messages = [];
  String? currentUserId;
  String? errorMessage;
  bool sending = false;

  bool isMine(ChatMessage m) => m.senderId == currentUserId;

  Future<void> init() async {
    currentUserId = await _profile.currentUserId();
    await load();
    _markUnreadAsRead();
  }

  Future<void> load() async {
    // Nouvelle conversation (bouton "Contacter") : pas encore d'historique.
    // La conversation sera créée côté backend au premier message envoyé.
    if (conversation.conversationId.isEmpty) return;

    setBusy(true);
    try {
      // Le backend renvoie du plus récent au plus ancien : on inverse
      final history = await _messages.getHistory(conversation.conversationId);
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
      messages.add(sent);
      inputController.clear();
      errorMessage = null;
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
    inputController.dispose();
    super.dispose();
  }
}
