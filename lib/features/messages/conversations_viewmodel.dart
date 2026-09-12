import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../app/app.locator.dart';
import '../../app/app.router.dart';
import '../../core/api/api_exception.dart';
import '../../services/message_service.dart';
import '../../shared/models/conversation_summary.dart';

/// Logique de la liste des conversations.
class ConversationsViewModel extends BaseViewModel {
  final MessageService _messages;
  final NavigationService _nav;

  ConversationsViewModel(
      {MessageService? messageService, NavigationService? navigationService})
      : _messages = messageService ?? locator<MessageService>(),
        _nav = navigationService ?? locator<NavigationService>();

  List<ConversationSummary> conversations = [];
  String? errorMessage;

  /// Filtre de recherche par nom de contact (vide = tout afficher)
  String query = '';

  /// Stale-while-revalidate (APP-122) : si on a déjà une liste en cache (d'une
  /// visite précédente), on l'affiche IMMÉDIATEMENT et on rafraîchit en fond,
  /// sans spinner. Seul le tout premier chargement (cache vide) montre le
  /// loader. Fini l'écran vide + spinner à chaque entrée sur l'onglet Messages.
  Future<void> load() async {
    final cache = _messages.cachedConversations;
    if (cache != null) {
      // On a du contenu à montrer tout de suite → pas de setBusy, pas de spinner
      conversations = cache;
      notifyListeners();
    } else {
      setBusy(true);
    }

    try {
      conversations = await _messages.getConversations();
      errorMessage = null;
    } on ApiException catch (e) {
      // On n'affiche l'erreur que si on n'a rien d'autre à montrer : hors ligne
      // avec une liste déjà à l'écran, on garde la liste plutôt qu'un message.
      if (conversations.isEmpty) errorMessage = e.message;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  /// Conversations visibles selon le filtre de recherche
  List<ConversationSummary> get conversationsFiltrees {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations
        .where((c) => c.partnerName.toLowerCase().contains(q))
        .toList();
  }

  /// true dès qu'on a au moins 2 conversations (on affiche alors la recherche)
  bool get afficheRecherche => conversations.length >= 2;

  /// Ouvre le chat, recharge au retour (les non-lus ont changé)
  Future<void> openConversation(ConversationSummary conversation) async {
    await _nav.navigateTo(
      Routes.chatView,
      arguments: ChatViewArguments(conversation: conversation),
    );
    await load();
  }
}
